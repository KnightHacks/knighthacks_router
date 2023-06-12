// At the router_service stage, register callbacks for processing
// responses. We are using a closure here, but it could be a
// function if we chose (see execution_service).
fn supergraph_service(service) {
    let map_callback = |response| {
        try {
            // Extract our set-cookie key from context
            // If there is no set-cookie key in our context,
            // there is no work to do.
            if response.context["set_cookie_headers"] != () {
                let header_value = response.context["set_cookie_headers"];
                response.headers["set-cookie"] = header_value;
            }
        }
        catch(err)
        {
            // log any errors
            log_error(`set-cookie not created: ${err}`);
        }
    };
  let add_cookies_to_response = |response| {
    if response.context["set_cookie_headers"]?.len > 0 {
      response.headers["set-cookie"] = response.context["set_cookie_headers"];
    }
  };

    service.map_response(add_cookies_to_response);
    service.map_response(map_callback);
}

fn subgraph_service(service, subgraph) {
    let store_cookies_from_subgraphs = |response| {
      if response.headers.values("set-cookie")?.len > 0 {
        if response.context["set_cookie_headers"] == () {
          response.context.set_cookie_headers = []
        }

        response.context.set_cookie_headers += response.headers.values("set-cookie");
      }
    };

    const request_callback = Fn("process_request");
    service.map_request(request_callback);

    service.map_response(store_cookies_from_subgraphs);
}

fn process_request(request) {
    // Find our cookies
    if "cookie" in request.headers {
        let cookies = request.headers["cookie"].split(';');
        for cookie in cookies {
            // Split our cookies into name and value
            let k_v = cookie.split('=', 2);
            if k_v.len() == 2 {
                // trim off any whitespace
                k_v[0].trim();
                k_v[1].trim();
                // update our headers
                // Note: we must update subgraph.headers, since we are
                // setting a header in our sub graph request
                request.subgraph.headers[k_v[0]] = k_v[1];
            }
        }
    }
}