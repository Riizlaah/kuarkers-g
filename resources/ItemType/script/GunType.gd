extends ItemType
class_name GunType

@export_range(5.0, 60.0) var cam_fov : float = 30.0
@export_range(5, 100) var bullet_damage : int = 5
@export_range(1, 21) var rate_of_fire := 5
@export_range(3, 80) var c_ammo : int = 30
@export_range(3, 80) var max_ammo : int = 30
@export_range(20, 180) var reload_time : int = 60
#@export_range(0, 180) var recoil : int = 60
