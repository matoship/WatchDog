import {Router} from "express";
import {addCaregiver, deleteCaregiver, getCaregiver, updateCaregiver}
  from "./Controllers/caregiversController";
import {addPatients, deletePatients, getPatients, updatePatients} from
  "./Controllers/patientController";
// eslint-disable-next-line new-cap
const router = Router();
// careGivers
router.post("/", addCaregiver);
router.put("/:id", updateCaregiver);
router.get("/:id", getCaregiver);
router.delete("/:id", deleteCaregiver);

// patientss
router.post("/", addPatients);
router.put("/:id", updatePatients);
router.get("/:id", getPatients);
router.delete("/:id", deletePatients);

export default router;
