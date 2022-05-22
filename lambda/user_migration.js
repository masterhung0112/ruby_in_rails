"use strict";

console.log("Loading function");

const http = require("http");
const https = require("https");

// Extract other attributes returned from Rails and convert into Cognito attributes
const attributes = (response) => {
  return {
    username: response.username,
    email: response.email,
    email_verified: "true",
    name: response.first_name + " " + response.last_name,
  };
};

const checkUser = (server, data, callback) => {
  let postData = JSON.stringify(data);
  console.log('Connect to', server, 'with data', postData);
  
  let options = {
    hostname: server,
    port: 3000,
    path: "/aws/auth",
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Content-Length": postData.length,
    },
  };

  let req = http.request(options, (res) => {
    let data = "";
    res.on("data", (chunk) => {
      data += chunk;
    });
    res.on("end", () => {
      if (data) {
        let response = JSON.parse(data);
        console.log("response:", JSON.stringify(response, null, 2));
        callback(null, response);
      } else {
        callback("Authentication error");
      }
    });
  });

  req.on("error", (e) => {
    callback(e);
  });

  req.write(postData);
  req.end();
};



exports.handler = (event, context, callback) => {
  console.log("Migrating user:", event.userName);

  let rails_server_url = process.env.rails_server_url || "http://172.31.24.139" || "http://13.229.223.132";
    //process.env.rails_server_url || "http://13.229.223.132";
  checkUser(
    rails_server_url,
    {
      email: event.userName,
      password: event.request && event.request.password,
      access_token: process.env.rails_server_access_token,
    },
    (err, response) => {
      if (err) {
        return context.fail("Connection error");
      }
      if (!event.response) {
        event.response = {};
      }
      if (event.triggerSource == "UserMigration_Authentication") {
        // authenticate the user with your existing user directory service
        if (response.success) {
          event.response.userAttributes = attributes(response);
          event.response.finalUserStatus = "CONFIRMED";
          event.response.messageAction = "SUPPRESS";
          console.log("Migrating user Success:", event.userName);
          context.succeed(event);
        } else if (response.user_exists) {
          context.fail("Bad password");
        } else {
          context.fail("Bad user");
        }
      } else if (event.triggerSource == "UserMigration_ForgotPassword") {
        if (response.user_exists) {
          event.response.userAttributes = attributes(response);
          event.response.messageAction = "SUPPRESS";
          console.log("Migrating user with password reset:", event.userName);
          context.succeed(event);
        } else {
          context.fail("Bad user");
        }
      } else {
        context.fail("Bad triggerSource " + event.triggerSource);
      }
    }
  );
};