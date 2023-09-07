/* eslint-disable max-len */
import {Response} from "firebase-functions/v1";
import {db} from "../config/firebase";
/*
caregivers
*/
type EntryType = {
    id: string,
    firstName: string,
    lastName: string,
    imageUrl:string,
    careGiverId:string,
    allowedInBed:boolean,
    allowedInRoom:boolean,
    roomNum:string,
    bedNum:string,
}

type Request ={
    query: any;
    body: EntryType,
    params:{id:string}
}


const addPatients = async (req: Request, res: Response) => {
  const {firstName, bedNum, roomNum, lastName, imageUrl, careGiverId, allowedInBed, allowedInRoom} = req.body;
  const entry = db.collection("patients").doc();

  const entryObject = {
    id: entry.id,
    imageUrl,
    firstName,
    lastName,
    careGiverId,
    allowedInBed,
    allowedInRoom,
    roomNum,
    bedNum,
  };

  try {
    await db.runTransaction(async (t) => {
      if (careGiverId) {
        const careGiverRef = db.collection("user").doc(careGiverId);
        const careGiverDoc = await t.get(careGiverRef);

        if (!careGiverDoc.exists) {
          throw new Error("No such care giver!");
        }

        const currentData = careGiverDoc.data() || {};
        let assignedPatients = currentData.assignedPatients || [];

        // Add new entry.id to the list of assignedPatients
        assignedPatients = [entry.id, ...assignedPatients];

        // Update the database
        await t.update(careGiverRef, {
          assignedPatients: assignedPatients,
        });
      } else {
        console.log("careGiverId is empty.");
      }

      // Add the new patient
      await t.set(entry, entryObject);
    });

    res.status(200).send({
      status: "success",
      message: "entry added successfully",
      data: entryObject,
    });
  } catch (error) {
    if (error instanceof Error) {
      res.status(500).json(error.message);
    } else {
      res.status(500).json("An unexpected error occurred");
    }
  }
};


const updatePatients = async (req: Request, res: Response): Promise<void> => {
  const {body: {firstName, roomNum, bedNum, lastName, imageUrl, careGiverId, allowedInBed, allowedInRoom},
    params: {id}} = req;
  try {
    const entry = db.collection("patients").doc(id);
    const currentData = (await entry.get()).data() || {};
    const entryObject = {
      firstName: firstName || currentData.firstName,
      lastName: lastName || currentData.lastName,
      imageUrl: imageUrl || currentData.imageUrl,
      careGiverId: careGiverId || currentData.careGiverId,
      allowedInBed: allowedInBed || currentData.allowedInBed,
      allowedInRoom: allowedInRoom || currentData.allowedInRoom,
      bedNum: bedNum || currentData.bedNum,
      roomNum: roomNum || currentData.roomNum,
    };

    await entry.set(entryObject).catch((error) => {
      res.status(400).json({
        status: "error",
        message: error.message,
      });
      throw new Error("Error setting entry"); // Adding this to halt execution
    });

    res.status(200).json({
      status: "success",
      message: "entry updated successfully",
      data: entryObject,
    });
  } catch (error) {
    if (error instanceof Error) {
      res.status(500).json(error.message);
    } else {
      res.status(500).json("An unexpected error occurred");
    }
  }
};


const deletePatients = async (req: Request, res: Response): Promise<void> => {
  const {id} = req.params;

  try {
    await db.runTransaction(async (t) => {
      const entryRef = db.collection("patients").doc(id);
      const entryDoc = await t.get(entryRef);

      if (!entryDoc.exists) {
        throw new Error("No such patient! Maybe it's already deleted.");
      }

      const careGiverId = entryDoc.data()?.careGiverId;

      if (careGiverId) {
        const careGiverRef = db.collection("user").doc(careGiverId);
        const careGiverDoc = await t.get(careGiverRef);

        if (!careGiverDoc.exists) {
          throw new Error("No such care giver!");
        }

        const currentData = careGiverDoc.data() || {};
        let assignedPatients = currentData.assignedPatients || [];

        // Remove the patient's id from the list of assignedPatients
        assignedPatients = assignedPatients.filter((patientId: string) => patientId !== id);

        // Update the database
        await t.update(careGiverRef, {
          assignedPatients: assignedPatients,
        });
      }

      // Delete the patient
      await t.delete(entryRef);
    });

    res.status(200).json({
      status: "success",
      message: "entry deleted successfully",
    });
  } catch (error) {
    if (error instanceof Error) {
      res.status(500).json(error.message);
    } else {
      res.status(500).json("An unexpected error occurred");
    }
  }
};


const getPatients = async (req: Request, res: Response): Promise<void> => {
  const {id} = req.params;
  try {
    const entry = db.collection("patients").doc(id);

    const data = await entry.get().catch((error) => {
      res.status(400).json({
        status: "error",
        message: error.message,
      });
      throw new Error("Error getting entry"); // Halting execution
    });

    res.status(200).json({
      status: "success",
      message: "entry retrieved successfully",
      data: [data.data()], // Assuming you want the data of the document
    });
  } catch (error) {
    if (error instanceof Error) {
      res.status(500).json(error.message);
    } else {
      res.status(500).json("An unexpected error occurred");
    }
  }
};

const getPatientsList = async (req: Request, res: Response): Promise<void> => {
  // Use req.query to capture query string parameters
  const id = req.query.id as string;

  try {
    // Get the collection reference
    const patientsCollection = db.collection("patients");

    // Perform a query to get all patient documents with the matching careGiverId
    // If id is not provided, it defaults to an empty string
    const querySnapshot = await patientsCollection.where("careGiverId", "==", id || null).get();

    // Convert the query results to an array of patient data
    const patients: EntryType[] = [];
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      patients.push({
        id: doc.id,
        ...data,
        firstName: data.firstName || "",
        lastName: data.lastName || "",
        imageUrl: data.imageUrl || "",
        careGiverId: data.careGiverId || "",
        allowedInBed: data.allowedInBed || false,
        allowedInRoom: data.allowedInRoom || false,
        roomNum: data.roomNum||"",
        bedNum: data.bedNUm||"",
      });
    });

    // Check if query returned any results
    if (patients.length === 0) {
      res.status(404).json({
        status: "error",
        message: "No entries found",
      });
      return;
    }

    // Send the patient data as a JSON response
    res.status(200).json({
      status: "success",
      message: "entries retrieved successfully",
      data: patients,
    });
  } catch (error) {
    if (error instanceof Error) {
      res.status(500).json(error.message);
    } else {
      res.status(500).json("An unexpected error occurred");
    }
  }
};


export {deletePatients, addPatients, updatePatients, getPatients, getPatientsList};


