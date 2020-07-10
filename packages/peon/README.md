# peon

A new Flutter project.

## Getting Started

setup your VSCode for some glory add a blob like this to get gud.

```json
{
    "name": "Peon",
    "program": "packages/peon/lib/main.dart",
    "request": "launch",
    "type": "dart",
    "env": {
        "AWS_ACCESS_KEY": "<your key>",
        "AWS_SECRET_KEY": "<tell us your secrets>",
        "AWS_QUEUE": "https://sqs.us-west-1.amazonaws.com/654831454668/tester"
    }
}
```

## push a message in.

- ping
`AWS_ACCESS_KEY=<key> AWS_SECRET_KEY=<secret> AWS_QUEUE=https://sqs.us-west-1.amazonaws.com/654831454668/tester dart lib/pumper.dart '{"action":"ping"}'`

- echo
`AWS_ACCESS_KEY=<key> AWS_SECRET_KEY=<secret> AWS_QUEUE=https://sqs.us-west-1.amazonaws.com/654831454668/tester dart lib/pumper.dart '{"action":"echo", "params":{"message":"bits"}}'`

- make a file
`AWS_ACCESS_KEY=<key> AWS_SECRET_KEY=<secret> AWS_QUEUE=https://sqs.us-west-1.amazonaws.com/654831454668/tester dart lib/pumper.dart '{"action":"makefile"}'`
