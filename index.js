const axios = require("axios");
const { createServer } = require("http");

const slackToken = "xoxb-2359270667718-2383288163893-F0SPsh181v1MzjohOcSY9ppj";

// run().catch((err) => console.log(err));

async function run() {
  // const url = "https://slack.com/api/chat.postMessage";
  // const res = await axios.post(
  //   url,
  //   {
  //     channel: "#local-server",
  //     text: "Hello, World!",
  //   },
  //   { headers: { authorization: `Bearer ${slackToken}` } }
  // );

  const url = "https://slack.com/api/oauth.v2.access";
  const res = await axios.post(url, {
    client_id: "2359270667718.2392497804644",
    client_secret: "61f6829c1dad5aa839f0007e2d8f1f0b",
  });

  console.log("Done", res.data);
}

const { InstallProvider } = require("@slack/oauth");

// initialize the installProvider
const installer = new InstallProvider({
  clientId: "2359270667718.2392497804644",
  clientSecret: "61f6829c1dad5aa839f0007e2d8f1f0b",
  stateSecret: "my-state-secret",
});

const server = createServer((req, res) => {
  // our redirect_uri is /slack/oauth_redirect
  if (req.url === "/slack/oauth_redirect") {
    // call installer.handleCallback to wrap up the install flow
    installer.handleCallback(req, res);
  }
});

server.listen(3000);
