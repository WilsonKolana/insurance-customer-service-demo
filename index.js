const dasha = require("@dasha.ai/sdk");
const fs = require("fs");

async function main() 
{
  const app = await dasha.deploy("./app");

  app.connectionProvider = async (conv) =>
    conv.input.phone === "chat"
      ? dasha.chat.connect(await dasha.chat.createConsoleChat())
      : dasha.sip.connect(new dasha.sip.Endpoint("default"));
  app.ttsDispatcher = () => "dasha";

  await app.start();

  // external function check policy number. Here we are providing a random evaluation, you will want to refer to your membership database 
  app.setExternal("check_policy", (args, conv) => 
{
  const policyNumber = args;
  console.log(policyNumber);

  const foo = Math.random();
  if (foo >=.4)
  {
    return "This is a valid policy number. And there is currently one active claim associated with this policy number.";
  }
  else return "There is no active policy with this number. I'm sorry.";
});

// external function convert policy number.
app.setExternal("convert_policy", (args, conv) => 
{
  var policyRead = args.policy_number.split('').join('. ');
  console.log(policyRead);
  return policyRead;
});

  // external function pre-existing conditions. Here we are providing a random response, you will want to refer to your membership database 
  app.setExternal("pre_existing", (args, conv) => 
{
  const foo = Math.random();
  console.log(foo);
  if (foo >=.45)
  {
    return " the policy holder has no pre-existing conditions on file.";
  }
  else return " the policy holder has diabetes as a pre-existing condition. Our policy on pre-existing conditions is that they are not covered for the first 12 months that the policyholder holds the policy. In the case of the policy number you were asking about, the member's pre-existing conditions will be coverable starting November twentieth 2021.";
});

// external function console.log
app.setExternal("console_log", (args, conv) => 
{
  console.log(args);
}); 

  const conv = app.createConversation({ phone: process.argv[2] ?? "", name: process.argv[3] ?? "" });

  if (conv.input.phone !== "chat") conv.on("transcription", console.log);

  const logFile = await fs.promises.open("./log.txt", "w");
  await logFile.appendFile("#".repeat(100) + "\n");

  conv.on("transcription", async (entry) => {
    await logFile.appendFile(`${entry.speaker}: ${entry.text}\n`);
  });

  conv.on("debugLog", async (event) => {
    if (event?.msg?.msgId === "RecognizedSpeechMessage") {
      const logEntry = event?.msg?.results[0]?.facts;
      await logFile.appendFile(JSON.stringify(logEntry, undefined, 2) + "\n");
    }
  });

  const result = await conv.execute();

  console.log(result.output);

  await app.stop();
  app.dispose();

  await logFile.close();
}

main().catch(() => {});
