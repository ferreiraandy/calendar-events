# Setup

* Create a project at https://console.developers.google.com
* Go to the `API Manager` and enable the `Drive` and `Calendar` APIs
* Go to `Credentials` and create a new OAuth Client ID of type 'Web application'
    * Use `http://localhost:4567/oauth2callback` as the redirect URL
    * Use `http://localhost:4567` as the JavaScript origin

Additional details on how to enable APIs and create credentials can be
found in the help guide in the console.

## Example Environment Settings

For convenience, application credentials can be read from the shell environment
or placed in a .env file.

After setup, your .env file might look something like:

```
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
```

# Running the calendar

To start the server, run

```
ruby app.rb
```

Open `http://localhost:4567/` in your browser to explore the calendar.

![Peek 2021-07-23 14-32](https://user-images.githubusercontent.com/16719922/126819932-618bb150-c8f8-4ca3-9ccd-8b19f45d57c4.gif)
