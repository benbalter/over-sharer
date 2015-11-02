# Over Sharer

An app to share individual Markdown files from private GitHub repositories with just a secret url

## What it does

Over Sharer creates a semi-secure way for you to share individual Markdown files stored in private GitHub repos with others, without requiring that they create a GitHub account or giving them access to the repository as a whole.

## How it works

When you visit Over Sharer, it'll prompt you to paste in the URL to a Markdown file on GitHub that you have access to. After asking you to authenticate to provide Over Sharer access to the repository, it'll store your application-specific access token and create a unique ID for the markdown file.

You can then freely send the resulting URL to anyone you'd like to share the document with. They simply click the link and see the rendered Markdown file, without having to sign up for GitHub or be granted access. Of course this also means that anyone with the URL can do the same.

Done sharing? Simply click the "Unshare" button at the top of the page and Over Sharer will forget about the document.

## Demo

[over-sharer.herokuapp.com](https://over-sharer.herokuapp.com/)

**Note**: You probably shouldn't use that to share anything sensitive. Service is provided *as is* and all that, with no warranty, implied or otherwise.

## Set up

Over Sharer is designed to work on Heroku, but you can use it anywhere that supports Sinatra.

1. Create [a new GitHub OAuth application](https://github.com/settings/applications/new)
2. Set the Application ID and secret as `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` environmental values via `heroku config set`
3. Set up Redis via `heroku addons:create heroku-redis:hobby-dev`
3. Profit

## Running locally

1. Follow the instructions above, adding the two environmental variables to a new `.env` file
1. `script/bootstrap`
2. Start the redis server, if you haven't already via `redis-server`
2. `script/server`
3. Open `localhost:9292` in your browser

## A note on security

You're allowing anyone in the world that gets that URL to view a file that's otherwise very securely stored in a GitHub repository. You should treat that URL like a password. Under the hood, each document ID is generated via `SecureRandom`. That said, you're also storing GitHub tokens (which can grant read/write access to your private repos) in Redis. There's a reason you generally want people to go through the pain of creating an account and setting up 2FA, especially if it's to protect your organization's secret sauce.
