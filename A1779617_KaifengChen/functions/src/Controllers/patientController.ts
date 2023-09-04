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
}

type Request ={
    body: EntryType,
    params:{id:string}
}

const addPatients = async (req:Request, res:Response)=>{
  const {firstName, lastName, imageUrl}=
    req.body;
  try {
    const entry = db.collection("patients").doc();
    const entryObject = {
      id: entry.id,
      imageUrl,
      firstName,
      lastName,
    };
    await entry.set(entryObject);

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
  const {body: {firstName, lastName, imageUrl},
    params: {id}} = req;
  try {
    const entry = db.collection("patients").doc(id);
    const currentData = (await entry.get()).data() || {};

    const entryObject = {
      firstName: firstName || currentData.firstName,
      lastName: lastName || currentData.lastName,
      imageUrl: imageUrl || currentData.imageUrl,
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
    const entry = db.collection("patients").doc(id);

    await entry.delete().catch((error) => {
      res.status(400).json({
        status: "error",
        message: error.message,
      });
      throw new Error("Error deleting entry"); // Halting execution
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
      data: data.data(), // Assuming you want the data of the document
    });
  } catch (error) {
    if (error instanceof Error) {
      res.status(500).json(error.message);
    } else {
      res.status(500).json("An unexpected error occurred");
    }
  }
};


export {deletePatients, addPatients, updatePatients, getPatients};


