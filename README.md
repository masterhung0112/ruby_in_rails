# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...


```
rails c
user_object = {USERNAME:"user_email5", PASSWORD:"Password123*"}; Cognito.create_user(user_object)

user_object = {USERNAME:"user_email4", PASSWORD:"Password123*"}; Cognito.authenticate(user_object)
```

CURL
```
curl -d '{"email":"admin2@gmail.com","password":"Testing1$","access_token":"xx"}' -H "Content-Type: application/json"  -X POST http://13.229.223.132:3000/aws/auth
```
