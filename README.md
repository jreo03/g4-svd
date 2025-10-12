# Godot 4 - Simulacra Vehicle Dynamics (pre-alpha | Godot 3-4 Port)
<img width="1152" height="648" alt="Simulacra Vehicle Dynamics (DEBUG) 13_10_2025 3_14_59 am" src="https://github.com/user-attachments/assets/77655791-53e0-43ec-b61c-1af0f84952a7" />
<img width="600" height="450" alt="image" src="https://github.com/user-attachments/assets/bcea596d-2d8e-46aa-987a-563785d35c8e" />

<sup><sub>https://www.curbsideclassic.com/blog/cc-outtake/cc-outtake-former-1987-1991-honda-crx-x-marks-the-spot/


vitavehicle alternative that's simpler to work with
this is a godot 4 conversion, so meshes are   yes

currently in testing phase, coherent documentation will come soon

please replace/delete assets referred in borrowed_assets.txt when publishing your game using this project

feel free to submit any issues


## notes when porting godot 3 code to godot 4
- transform.xform(vector) -> transform*vector
- transform.xform_inv(vector) -> vector*transform
- global_translation -> global_transform.origin
