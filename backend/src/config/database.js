const mongoose = require("mongoose");

const connectDatabase = async () => {
  try {
    console.log("Connecting to MongoDB...");

    await mongoose.connect(process.env.MONGO_URI, {
      serverSelectionTimeoutMS: 10000,
    });

    console.log("MongoDB connected successfully");

    // Attempt to drop the obsolete 'mobile_1' index if it exists in the 'users' collection
    try {
      const db = mongoose.connection.db;
      const collections = await db.listCollections({ name: 'users' }).toArray();
      if (collections.length > 0) {
        const indexes = await db.collection('users').indexes();
        const hasMobileIndex = indexes.some(idx => idx.name === 'mobile_1');

        if (hasMobileIndex) {
          console.log("Dropping obsolete 'mobile_1' index...");
          await db.collection('users').dropIndex("mobile_1");
          console.log("Index 'mobile_1' dropped successfully");
        }
      }
    } catch (indexError) {
      // Ignore errors if the index doesn't exist or collection isn't initialized
      console.log("Note: Obsolete index cleanup skipped or not needed:", indexError.message);
    }

  } catch (error) {
    console.error("MongoDB connection failed:");
    console.error(error);
    throw error;
  }
};

module.exports = connectDatabase;
