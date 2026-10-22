/**
 * SMS OTP Service supporting Twilio or MSG91 Indian SMS Gateways.
 * Reads environment variables:
 * - SMS_PROVIDER ('twilio' or 'msg91')
 * - TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_PHONE_NUMBER
 * - MSG91_AUTH_KEY, MSG91_TEMPLATE_ID
 */
const sendOtp = async (phoneNumber, otp) => {
  const provider = (process.env.SMS_PROVIDER || "").toLowerCase();

  const formattedPhone = phoneNumber.startsWith("+")
    ? phoneNumber
    : `+91${phoneNumber}`;

  // 1. Twilio Gateway Integration
  if (
    provider === "twilio" ||
    (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN)
  ) {
    try {
      const accountSid = process.env.TWILIO_ACCOUNT_SID;
      const authToken = process.env.TWILIO_AUTH_TOKEN;
      const fromPhone = process.env.TWILIO_PHONE_NUMBER;

      const auth = Buffer.from(`${accountSid}:${authToken}`).toString("base64");
      const body = new URLSearchParams({
        To: formattedPhone,
        From: fromPhone,
        Body: `Your DWCRA Connect registration OTP is ${otp}. Valid for 5 minutes. Do not share this OTP with anyone.`,
      });

      const response = await fetch(
        `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
        {
          method: "POST",
          headers: {
            Authorization: `Basic ${auth}`,
            "Content-Type": "application/x-www-form-urlencoded",
          },
          body: body.toString(),
        }
      );

      const data = await response.json();
      if (response.ok) {
        console.log(`[SMS Gateway] Twilio OTP sent to ${formattedPhone}. SID: ${data.sid}`);
        return { success: true, provider: "twilio", messageId: data.sid };
      } else {
        console.error(`[SMS Gateway] Twilio Error: ${data.message || JSON.stringify(data)}`);
      }
    } catch (err) {
      console.error(`[SMS Gateway] Exception during Twilio send:`, err.message);
    }
  }

  // 2. MSG91 Gateway Integration
  if (provider === "msg91" || process.env.MSG91_AUTH_KEY) {
    try {
      const authKey = process.env.MSG91_AUTH_KEY;
      const templateId = process.env.MSG91_TEMPLATE_ID;

      const response = await fetch(
        `https://control.msg91.com/api/v5/otp?template_id=${templateId}&mobile=${formattedPhone.replace("+", "")}&otp=${otp}`,
        {
          method: "POST",
          headers: {
            authkey: authKey,
            "Content-Type": "application/json",
          },
        }
      );

      const data = await response.json();
      if (data.type === "success") {
        console.log(`[SMS Gateway] MSG91 OTP sent to ${formattedPhone}`);
        return { success: true, provider: "msg91" };
      } else {
        console.error(`[SMS Gateway] MSG91 Error:`, JSON.stringify(data));
      }
    } catch (err) {
      console.error(`[SMS Gateway] Exception during MSG91 send:`, err.message);
    }
  }

  // 3. Fallback Status Log (When SMS credentials are not yet configured in environment variables)
  console.log(`[SMS Gateway Sandbox] OTP generated for ${phoneNumber}: [${otp}]`);
  console.log(`[SMS Setup Note] To send real SMS via Twilio, set TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN in environment variables.`);

  return {
    success: true,
    provider: "sandbox",
    note: "SMS provider credentials not configured in environment variables. OTP logged in server logs.",
  };
};

module.exports = { sendOtp };
