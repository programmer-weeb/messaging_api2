# messaging_api2

Rails 8 API-only backend for a small messaging app. Users sign up with email/password or Google, send direct messages, and manage friendship requests. Authentication is JWT (via `devise-jwt`) with a database denylist for revocation on logout.

## Setup

```bash
bin/setup        # install gems, prepare DB, start dev process
# or step by step:
bundle install
bin/rails db:prepare
```

### Credentials

Set the following with `bin/rails credentials:edit`:

```yaml
devise_jwt_secret_key: <hex string, 64+ chars>
google:
  client_ids:
    - <web client id>
    - <ios/android client id (optional)>
mailer:
  from: no-reply@yourdomain.tld
```

### CORS

`config/initializers/cors.rb` currently allows `origins "*"`. Lock this down to your trusted frontend origins before any production deploy.

## API surface

Auth (Devise + JWT, returns `Authorization: Bearer <token>` header on success):

| Method | Path           | Notes                         |
| ------ | -------------- | ----------------------------- |
| POST   | `/signup`      | email + password registration |
| POST   | `/login`       | email + password sign-in      |
| POST   | `/auth/google` | Google ID token sign-in       |
| DELETE | `/logout`      | revokes current JWT           |

Users:

| Method | Path         | Notes                                  |
| ------ | ------------ | -------------------------------------- |
| GET    | `/me`        | current user                           |
| GET    | `/users`     | directory, supports `?q=` email prefix |
| GET    | `/users/:id` | profile                                |

Messages (all require auth):

| Method | Path                              | Notes                                 |
| ------ | --------------------------------- | ------------------------------------- |
| GET    | `/messages`                       | inbox (sent + received)               |
| GET    | `/messages/sent`                  | sent only                             |
| GET    | `/messages/received`              | received only                         |
| GET    | `/messages/conversations`         | grouped per partner                   |
| GET    | `/messages/conversation/:user_id` | full thread with one user             |
| GET    | `/messages/:id`                   | participant only                      |
| POST   | `/messages`                       | `{ message: { recipient_id, body } }` |
| DELETE | `/messages/:id`                   | sender only                           |

Friendships (all require auth):

| Method | Path                       | Notes                               |
| ------ | -------------------------- | ----------------------------------- |
| GET    | `/friendships`             | grouped: accepted/pending_sent/etc. |
| GET    | `/friendships/:id`         | participant only                    |
| POST   | `/friendships`             | `{ friendship: { addressee_id } }`  |
| PATCH  | `/friendships/:id/accept`  | addressee only                      |
| PATCH  | `/friendships/:id/decline` | addressee only (destroys record)    |
| PATCH  | `/friendships/:id/block`   | participant only                    |
| DELETE | `/friendships/:id`         | participant only                    |
