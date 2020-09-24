###
#### How to run
```bash
./deploy.sh

```

### Decomission
```bash
./deploy.sh yes

```


* [Issue Template error: Fn::Select cannot select nonexistent value at index 2](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getavailabilityzones.html)
You need to check that your region has at least 3 Aviability Zones

Kudos:
* Using https://github.com/jkehler/awslambda-psycopg2 for Lambda ( [link](https://stackoverflow.com/questions/36607952/using-psycopg2-with-lambda-to-update-redshift-python) )
