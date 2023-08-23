import {Response} from "firebase-functions/v1";
import {db} from "./config/firebase";

/*
caregivers
*/
type EntryType = {
    firstName: string,
    lastName: string,
    email: string,
    phone: string,
    assignedPatients:object
}

type Request ={
    body: EntryType,
    params:{id:string}
}

const addCaregiver = async (req:Request, res:Response)=>{
  const {firstName, lastName, email, phone, assignedPatients}=req.body;
  try {
    const entry = db.collection("user").doc();
    const entryObject = {
      id: entry.id,
      firstName,
      lastName,
      email,
      phone,
      assignedPatients,
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

const updateCaregiver = async (req: Request, res: Response): Promise<void> => {
  const {body: {firstName, lastName, email, phone, assignedPatients},
    params: {id}} = req;
  try {
    const entry = db.collection("user").doc(id);
    const currentData = (await entry.get()).data() || {};

    const entryObject = {
      firstName: firstName || currentData.firstName,
      lastName: lastName || currentData.lastName,
      email: email || currentData.email,
      phone: phone || currentData.phone,
      assignedPatients: assignedPatients ?
        {...currentData.assignedPatients, ...assignedPatients} :
        currentData.assignedPatients,
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


const deleteCaregiver = async (req: Request, res: Response): Promise<void> => {
  const {id} = req.params;

  try {
    const entry = db.collection("user").doc(id);

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

const getCaregiver = async (req: Request, res: Response): Promise<void> => {
  const {id} = req.params;
  try {
    const entry = db.collection("user").doc(id);

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


export {deleteCaregiver, addCaregiver, updateCaregiver, getCaregiver};

/*
patients
*/
