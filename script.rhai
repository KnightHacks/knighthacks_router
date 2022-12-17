// At the router_service stage, register callbacks for processing
// responses. We are using a closure here, but it could be a
// function if we chose (see execution_service).
fn supergraph_service(service) {
    print(`registered callback for service ${service}`);
    let map_callback = |response| {
        try {
            // Extract our set-cookie key from context
            // If there is no set-cookie key in our context,
            // there is no work to do.
            print(`response.context=${response.context}`);
            if response.context["set-cookie"] != () {
                let header_value = response.context["set-cookie"];
                print(`set-cookie=${header_value}`);
                response.headers["set-cookie"] = header_value;
            }
        }
        catch(err)
        {
            // log any errors
            log_error(`set-cookie not created: ${err}`);
        }
    };
    // Map our response using our closure
    service.map_response(map_callback);
}

// At the subgraph_service stage, register callbacks for processing
// responses.
// We are going to use two closures here:
//  - map_callback to map and manipulate the service response
//  - resolver to provide an upserting function for the context
//    upsert.
// If we can't find headers or a cache-key, we don't want to fail,
// so catch the error and log it out.
fn subgraph_service(service, subgraph) {
    // client cookie -> subgraph header
    print(`registering request callback for ${subgraph}`);
    const request_callback = Fn("process_request");
    service.map_request(request_callback);


    // subgraph -> client cookie
    let map_callback = |response| {
        try {
            print(`headers= ${response.headers}`);
            let my_cache_key = response.headers["set-cookie"];
            // Upsert our context with our resolver
            response.context["set-cookie"] = my_cache_key;
            print(`found set-cookie header with value: ${my_cache_key}`);
        }
        catch(err)
        {
            // Log out
            print(`cache-key not found: ${err}`);
        }
    };
    // Map our response using our closure
    service.map_response(map_callback);
}

// This will convert all cookie pairs into headers.
// If you only wish to convert certain cookies, you
// can add logic to modify the processing.
fn process_request(request) {

    // Find our cookies
    if "cookie" in request.headers {
        print("adding cookies as headers");
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
    } else {
        print("no cookies in request");
    }
}