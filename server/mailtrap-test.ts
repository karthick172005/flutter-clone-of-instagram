import dotenv from 'dotenv';
import nodemailer from 'nodemailer';

// 👇 Load environment variables from server/config/config.env
dotenv.config({ path: __dirname + '/config/config.env' });

console.log('📦 Loaded config:', {
  host: process.env.EMAIL_HOST,
  port: process.env.EMAIL_PORT,
  user: process.env.EMAIL_USERNAME,
});

const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST,
  port: Number(process.env.EMAIL_PORT),
  auth: {
    user: process.env.EMAIL_USERNAME,
    pass: process.env.EMAIL_PASSWORD
  }
});

const mailOptions = {
  from: '"Instagram Clone" <noreply@instagram-clone.com>',
  to: 'karthickkrishna2005@gmail.com', // replace with your email (must be verified in Mailtrap)
  subject: 'Mailtrap Test',
  text: 'Hello from Mailtrap!'
};

transporter.sendMail(mailOptions)
  .then(info => console.log('✅ Email sent:', info.response))
  .catch(err => console.error('❌ Failed to send:', err));
