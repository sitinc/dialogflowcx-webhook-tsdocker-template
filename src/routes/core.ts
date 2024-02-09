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

// Example tag route for 'New Interaction' tag.
const newInteractionRoute = new class implements TagRouter {
    public tagName: string = 'New Interaction'; // Dialogflow CX Tag value.

    /**
     * Handle the webhook request.
     * @param context The webhook context.
     * @returns the updated webhook context.
     */
    async handle(context: WebhookContext): Promise<WebhookContext> {
        const sessionId = crypto.randomUUID();
        context.params.sessionId = sessionId;
        
        // Access the root of Dialoflow CX Parameters.
        const sessionParams = context.req.body.sessionInfo.parameters;

        // TODO: The needful.

        return context;
    }
}
router.use(newInteractionRoute.tagName, newInteractionRoute);

export = router;
