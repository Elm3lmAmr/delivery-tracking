'use strict';

// Provider-agnostic SMS sender. Swap the `stub` block for Vonage / Twilio / Msegat when ready.
async function send(phone, message) {
  const provider = process.env.SMS_PROVIDER || 'stub';

  if (provider === 'stub') {
    console.log(`[sms:stub] to=${phone} msg=${message}`);
    return { sent: true, provider: 'stub' };
  }

  if (provider === 'vonage') {
    // Example integration (uncomment and add @vonage/server-sdk to package.json):
    // const { Vonage } = require('@vonage/server-sdk');
    // const vonage = new Vonage({ apiKey: process.env.SMS_API_KEY, apiSecret: process.env.SMS_API_SECRET });
    // await vonage.sms.send({ from: process.env.SMS_SENDER_ID, to: phone, text: message });
    throw new Error('Vonage integration not wired yet');
  }

  if (provider === 'twilio') {
    // Example integration (uncomment and add twilio to package.json):
    // const twilio = require('twilio')(process.env.SMS_API_KEY, process.env.SMS_API_SECRET);
    // await twilio.messages.create({ from: process.env.SMS_SENDER_ID, to: phone, body: message });
    throw new Error('Twilio integration not wired yet');
  }

  throw new Error(`Unknown SMS provider: ${provider}`);
}

module.exports = { send };
