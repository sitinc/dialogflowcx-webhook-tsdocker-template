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
import express, { Request, Response } from 'express';
import crypto from 'crypto';

import { WebhookContext, WebhookRouter } from '@sitinc/dialogflowcx-tagexpress';
import CoreRouter from './core';

const webhookRouter = new WebhookRouter();
webhookRouter.useRouter(CoreRouter);

// Create the router.
const router = express.Router();

// Expose static endpoint.
router.use('/static', express.static('static'));

// Expose the HTTP POST handler.
router.post('/', async (req: Request, res: Response) => {
    console.log(`req.body: ${JSON.stringify(req.body)}`);
    
    const transId = crypto.randomUUID();

    const params = req.body.sessionInfo?.parameters;
    const tagName = req.body.fulfillmentInfo?.tag;

    const resPayload = {
        transId: transId,
        retval: -1,
        retmsg: 'Unhandled',
        sessionInfo: {},
    };

    let webbookContext = new WebhookContext(transId, req, res);

    webbookContext = await webhookRouter.handle(tagName, webbookContext);

    resPayload.sessionInfo = {
        parameters: {
          ...req.body.sessionInfo?.parameters,
          ...webbookContext.params,
        },
    };
    resPayload.retval = 0;
    resPayload.retmsg = 'Success';

    res.status(200).send(resPayload);
});

export = router;
