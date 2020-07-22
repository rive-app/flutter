# peon_process

A new Flutter project.

## Getting Started

setup your VSCode for some glory add a blob like this to get gud.

```json
{
    "name": "Peon",
    "program": "packages/peon_process/lib/main.dart",
    "request": "launch",
    "type": "dart",
    "env": {
        "AWS_ACCESS_KEY": "<your key>",
        "AWS_SECRET_KEY": "<tell us your secrets>",
        "AWS_DART_QUEUE": "https://sqs.us-west-1.amazonaws.com/654831454668/tester",
        "AWS_JS_QUEUE": "https://sqs.us-west-1.amazonaws.com/654831454668/tester"
    }
}
```

## push a message in.

Go check out the peon package.