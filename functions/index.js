const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// ------------------------------
// Create New User (Admin Only)
// ------------------------------
exports.createUserForAdmin = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User creation must be performed by an authenticated Admin.",
    );
  }

  try {
    const userRecord = await admin.auth().createUser({
      email: request.data.email,
      password: request.data.password,
      displayName: request.data.displayName,
    });

    return {uid: userRecord.uid};
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError(
          "already-exists",
          "The email address is already in use.",
      );
    }

    throw new HttpsError("unknown", error.message);
  }
});

// ------------------------------
// Disable User (Admin Only)
// ------------------------------
exports.disableUser = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User creation must be performed by an authenticated Admin.",
    );
  }

  const targetUid = request.data.uid;

  if (!targetUid) {
    throw new HttpsError(
        "invalid-argument",
        "The 'uid' field is required.",
    );
  }

  try {
    await admin.auth().updateUser(targetUid, {disabled: true});
    return {success: true};
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      throw new HttpsError(
          "not-found",
          `The user with UID ${targetUid} was not found.`,
      );
    }
    throw new HttpsError("internal", error.message);
  }
});

// ------------------------------
// Enable User (Admin Only)
// ------------------------------
exports.enableUser = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User creation must be performed by an authenticated Admin.",
    );
  }

  const targetUid = request.data.uid;

  if (!targetUid) {
    throw new HttpsError(
        "invalid-argument",
        "The 'uid' field is required.",
    );
  }

  try {
    await admin.auth().updateUser(targetUid, {disabled: false});
    return {success: true};
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      throw new HttpsError(
          "not-found",
          `The user with UID ${targetUid} was not found.`,
      );
    }
    throw new HttpsError("internal", error.message);
  }
});

// ------------------------------
// Update User (Admin Only)
// ------------------------------
exports.updateUserDisplayName = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User creation must be performed by an authenticated Admin.",
    );
  }

  const targetUid = request.data.uid;

  if (!targetUid) {
    throw new HttpsError(
        "invalid-argument",
        "The 'uid' field is required.",
    );
  }

  try {
    await admin.auth().updateUser(targetUid,
        {displayName: request.data.displayName});
    return {success: true};
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      throw new HttpsError(
          "not-found",
          `The user with UID ${targetUid} was not found.`,
      );
    }
    throw new HttpsError("internal", error.message);
  }
});

// ------------------------------
// Email Transporter
// ------------------------------
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// ------------------------------
// Send Contact Form Email
// ------------------------------
exports.sendContactEmail = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "You must be logged in to submit a message.",
    );
  }

  const {
    id,
    userName,
    email,
    mobile,
    message,
    messageSentOn,
  } = request.data;

  if (!userName || !message) {
    throw new HttpsError(
        "invalid-argument",
        "Required fields missing.",
    );
  }

  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: process.env.EMAIL_USER,
    subject: `Contact Message from ${userName}`,
    html: `
<div>
  <p>A user has contaced you from the contact me page.
  The details are as below</p>

  <!-- Table to display the data in key-value pairs -->
  <table>
    <tbody>
      <!-- Row 1: Name -->
      <tr>
        <td><b>Name</b></td>
        <td>:   ${userName}</td>
      </tr>
      <!-- Row 2: Email -->
      <tr>
        <td><b>Email</b></td>
        <td>:   ${email || "Not provided"}</td>
      </tr>
      <!-- Row 3: Mobile -->
      <tr>
        <td><b>Mobile</b></td>
        <td>:   ${mobile || "Not provided"}</td>
      </tr>
      <!-- Row 4: Sent On -->
      <tr>
        <td><b>Sent On</b></td>
        <td>:   ${messageSentOn}</td>
      </tr>
      <!-- Row 5: Document ID -->
      <tr>
        <td><b>Doc ID</b></td>
        <td>:   ${id}</td>
      </tr>
    </tbody>
  </table>

  <div>
    <h4>Message :</h4>
    <p>${message}</p>
  </div>
</div>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    return {success: true};
  } catch (error) {
    throw new HttpsError("internal", error.message);
  }
});

// ------------------------------
// Update User Email (Admin Only)
// ------------------------------
exports.updateUserEmail = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User updation must be performed by an authenticated Admin.",
    );
  }

  try {
    const targetUid = request.data.uid;
    await admin.auth().updateUser(targetUid, {email: request.data.email});

    return {success: true, message: "Email updated successfully"};
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError(
          "already-exists",
          "The email address is already in use.",
      );
    }

    throw new HttpsError("unknown", error.message);
  }
});
