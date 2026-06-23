import azure.functions as func
import datetime
import json
import logging
import os
import requests

app = func.FunctionApp()

@app.function_name(name="HttpTrigger1")
@app.route(route="HttpExample", auth_level=func.AuthLevel.ANONYMOUS)
def HttpExample(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    name = req.params.get('name')
    if not name:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            name = req_body.get('name')

    headers = dict(req.headers)

    response_body = {
        "message": f"Hello, {name}." if name else "Hello!",
        "headers": headers
    }

    return func.HttpResponse(
            json.dumps(response_body, indent=2),
            status_code=200,
            mimetype="application/json"
    )
