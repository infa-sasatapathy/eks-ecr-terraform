# Base image
FROM node:18

# Set the working directory
WORKDIR /usr/src/app

# Copy package.json and install dependencies
COPY package.json ./
RUN npm install

# Copy the app source code
COPY . .

# Expose the port
EXPOSE 3000

# Start the application
CMD ["node", "src/000.js"]


