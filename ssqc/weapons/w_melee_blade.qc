/*  
	w_melee_blade.qc
	
	Clone of Wrath's "Blade of Ruination" or "Runination Blade" for Quake
	
	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.
	
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
	or on the interweb @ https://www.gnu.org/licenses/gpl-2.0.html
	See file, 'gnu_gpl.txt', for details.
*/

/*
	T O D O :

	Add Blocking
		Condition
		Animation
		Effect/Feedback
*/

// prototypes
void() player_run;
void() player_axe1;
void() player_axeb1;
void() player_axec1;
void() player_axed1;

.float melee_amount;
//.float melee_blocking;

void() Blade_Swing_Attack =
{
	self.weaponframe = self.frame = 1;
	sound (self, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM);
	float r = random();
	if (r < 0.25)
		player_axe1 ();
	else if (r<0.5)
		player_axeb1 ();
	else if (r<0.75)
		player_axec1 ();
	else
		player_axed1 ();
};

void() Blade_Clear_Attack =
{
	self.touch = SUB_Null;
	self.melee_amount = 0;
	self.weaponframe = 0;
	self.think = player_run;
	self.nextthink = time + 0.05;
//	self.melee_blocking = FALSE;
	self.attack_finished = time + 0.05;
};

void() Blade_Touch =
{
	if (other != world)
	{
		if ((other.classname == "player") && (other.health))
		{
			te_blood(other.origin, '0 0 0', 20);
			T_Damage (other, self, self, self.melee_amount + 25); 
			self.touch = SUB_Null;
		}			
	}
};

/*
==============================
	B L A D E  D A M A G E
==============================
	Inflict damage to entities directly in front of the Dash; pass damage to collision.
==============================	
*/
void() Blade_Damage =
{
	local	vector	source;
	local	vector	org;

	makevectors(self.v_angle);
	source = self.origin + '0 0 24' - v_forward * 8;
	tracebox(source, '-7 -7 -7', '7 7 7', source + v_forward * 200, FALSE, self);

	if (trace_fraction == 1.0)
	{
		sound (self, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM);
	}
	else
	{
		org = trace_endpos - v_forward * 4;

		if (trace_ent.takedamage)
		{
//			if (other.melee_blocking == FALSE)
			{				
				if (trace_ent.classname == "player")
					te_blood(org, '0 0 0', 20);//only players bleed
				else
					te_superspike(org);
				T_Damage (trace_ent, self, self, self.melee_amount * 12); // (120 points max)
			}
			// else // Deflect the Attack
			// {
			// 	// But Also Cancel the target's Blade_Charge too...
			// 	sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
			// 	other.weapon = 0; // Okay, this is a hack...
			// }
		}
	}

	self.touch = Blade_Touch;
	self.think = Blade_Clear_Attack;
	self.nextthink = time + 1;//last chance to get'em!
};

/*
==============================
  B L A D E  D A S H

  Thrust player towards forward aim. 
  Velocity determined by angle, flight and charge.
==============================
*/
void() Blade_Dash =
{		
	if (self.stoptime > time)			//R00k: Let's just get this out of the way...
	{
		self.think = w_melee_release;
		self.nextthink = time + 0.05;
		return;
	}

	float vrange = (90 - fabs(self.v_angle_x)) / 90;
	float charge = 1;//clamp(self.attack_finished - time, 0.05, 1);		// determine duration of charge and clamp it.
	float secondary_jump = 0;

	self.totallungetime = time;
	self.melee_released = (self.melee_released >=1) ? 2:1;
	self.vweaponframe 	= 26;
	
	dprint(sprintf("melee_released: %s\n",ftos(self.melee_released)));
	
	if (self.melee_released == 2)
	if ((!(self.flags & FL_ONGROUND))
		secondary_jump = 1;
	
	if (self.lungefree > time)
		secondary_jump = 0;

	makevectors (self.v_angle);	

 	if (self.v_angle_x > 23)										// Downwards; launching off a ledge
	{
		self.velocity = v_forward * 800 * charge;					// reduced dash velocity
		sound (self, CHAN_VOICE, "weapons/attack6.ogg", 1, ATTN_NORM);
	}
	else
	{
		makevectors (self.angles);									// use self.angles 
		self.velocity = v_forward * ((1024 * charge) * vrange) ;	// maximum velocity based on angle, and charge

		if (self.flags & FL_ONGROUND)								// Override the vertical velocity; snapping to preset heights.
		{
			if ( self.v_angle_x 	<	-45)
				self.velocity_z 	=	320;
			else
			if ( self.v_angle_x 	<= 	-10)
				self.velocity_z 	=  	270;
			else
				self.velocity_z 	= 	160;
		}
		else
		{
			if ( self.v_angle_x 	< 	-45)
				self.velocity_z 	= 	192;
			else
			if ( self.v_angle_x 	<= 	-10)
				self.velocity_z 	= 	160;
			else	
				self.velocity_z 	= 	96;
		}
	
		if ((vrange * charge) > 0.7)
			sound (self, CHAN_VOICE, "weapons/attack8.ogg", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "weapons/attack7.ogg", 1, ATTN_NORM);
	}

	self.melee_amount = charge * 10;
	self.attack_finished = time + 0.5;
	self.nextthink = time + 0.01;
	self.think = Blade_Damage;	
};

void() Blade_Charge =
{
	if (self.weapon != IT_AXE)
	{
		Blade_Clear_Attack();
		self.attack_finished = time + 0.3;
		return;
	}

	if (self.button0)
	{			
		self.nextthink = time + 0.05;		
		self.think = Blade_Charge;
		self.weaponframe += 1;

		if (((self.attack_finished - time) > 1) || (self.weaponframe >= 9))
		{
			//TODO: Run windUp animations here...
			//self.frame = 139;		
			//self.weaponframe = 9;
			self.weaponframe = 9;		
			//self.melee_blocking = TRUE;
		}

		//TODO: add increasing glowing effect here...		
		if (self.attack_finished > time)
			self.attack_finished += 0.1;//  1 second for full charge
		else
			self.attack_finished = time + 0.1;
	}
	else
	{	// TODO: Assign the swing to another button?
		if ((self.attack_finished - time) <= 1)	// If just a quick press then swing!
		{
			Blade_Swing_Attack();
		}
		else
		{
			self.frame = 139;
			self.weaponframe = 9;
			//self.melee_blocking = FALSE;
			self.nextthink = time + 0.05;
			self.think = Blade_Dash;
		}
	}
};

/*----------------------------------------------------------------------------//
Combined Swing Attacks with Charge-Attack button0; tapping the key activates the swing.
Changed required duration of charge to 1 second, instead of full charge persistantly

//----------------------------------------------------------------------------*/

//EOF