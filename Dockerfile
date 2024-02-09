# MIT License
#
# Copyright (c) 2024 Smart Interactive Transformations Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# First-stage build.
# Set image and workdir.
FROM node:21-slim AS build
ARG NPM_TOKEN
WORKDIR /usr/src/app

# Make directories
RUN mkdir -p ./src
RUN mkdir -p ./dist
RUN mkdir -p ./static

# Copy static files.
COPY package*.json ./
COPY ./tsconfig.json ./
COPY ./src/ ./src/
COPY ./static/ ./static/

# Single download, build, prune, remove command.
RUN echo "//registry.npmjs.org/:_authToken=$NPM_TOKEN" > .npmrc && \
    npm ci && \
    npm run build && \
    npm prune --production \
    rm -f .npmrc

# Second-stage build.
# Set image and workdir.
FROM node:21-slim
WORKDIR /usr/src/app

COPY --from=build /usr/src/app /usr/src/app

EXPOSE 8080

# Invoke the entry point.
CMD [ "node", "dist/server.js" ]