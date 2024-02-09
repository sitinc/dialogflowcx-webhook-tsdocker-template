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
import express, { Express, Request, Response } from 'express';
import bodyParser from 'body-parser';
import cors from 'cors';
import nocache from 'nocache';
import timeout from 'connect-timeout';
import dotenv from 'dotenv';
import Routers from './routes';
import swaggerUi from 'swagger-ui-express';

dotenv.config();

import * as swaggerDoc from './swagger.json';

// Create and configure Express entry point.
const app: Express = express();
const timeoutValue: string = process.env.SVC_TIMEOUT || '8s';
const portValue: number = parseInt(process.env.SVC_PORT || '8080');
const titleValue: string = process.env.SVC_TITLE || 'The test page!';
const swaggerPathValue: string = process.env.SWAGGER_PATH || '/swagger-ui';

// Disable caching.
app.set('etag', false);
app.use(nocache());

// Parse HTTP body parameters.
app.use(bodyParser.urlencoded({extended: true}));
app.use(bodyParser.json());

// Allow CORS from all domains.
app.use(cors({origin: '*'}));

// Handle timeout.
app.use(timeout(timeoutValue), haltOnTimedout);

/**
 * Callback to handle timeout invocations.
 * @param req  The HTTP request.
 * @param res  The HTTP response.
 * @param next The next callback in the chain.
 */
function haltOnTimedout(req: Request, res: Response, next: express.NextFunction) {
  if (req.timedout) {
    res.status(408).send('Request Timeout');
  }
  next();
}

// Expose swagger UI.
const swaggerOptions = {
  validatorUrl: null,
};
const swaggerUiOptions = {
  customSiteTitle: titleValue,
  swaggerOptions: swaggerOptions,
};
app.use(
  swaggerPathValue,
  swaggerUi.serve,
  swaggerUi.setup(swaggerDoc, swaggerUiOptions), 
);

// Pass POST / requests to the handler entry point.
app.use(Routers);

// Debug startup port.
app.listen(portValue, () => {
  console.log(`listening on port ${portValue}`);
});
