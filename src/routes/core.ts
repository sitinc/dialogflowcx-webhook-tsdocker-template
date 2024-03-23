/**
 * MIT License
 *
 * Copyright (c) 2024 Smart Interactive Transformations Inc.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */
import crypto from 'crypto';

import { TagRouter, WebhookContext, WebhookRouter } from "@sitinc/dialogflowcx-tagexpress";

const router = new WebhookRouter();

// Repeat the below create/register pattern for every new webhook "tag" handler.

// Create the example Dialogflow CX "tag" router for the 'New' webhook tag.
const newInteractionRoute = new class implements TagRouter {
    public tagName: string = 'New'; // Dialogflow CX Tag value.

    /**
     * Handle the webhook request.
     * @param context The webhook context.
     * @returns the updated webhook context.
     */
    async handle(context: WebhookContext): Promise<WebhookContext> {
        const sessionId = crypto.randomUUID();
        context.params.sessionId = sessionId;
        
        // Root of Dialoflow CX Webhook Request Data.
        const requestBody = context.req.body.sessionInfo.parameters;

        // Root of Dialoflow CX Context Parameters.
        const sessionParams = requestBody.sessionInfo.parameters;

        // TODO: The needful.
        /*
         * Here's a trivial example of read and updating Dialogflow context
         * parameters.
         */
        const name = sessionParams.api_name || 'World';

        sessionParams.api_session_id = sessionId
        sessionParams.api_msg = `Hello, ${name}!`

        return context;
    }
}
// Register the tag router for webhook tag 'New'.
router.use(newInteractionRoute.tagName, newInteractionRoute);

export = router;
