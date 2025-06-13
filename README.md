# flutter_liquid_glass
attempt at implementing liquid glass specifications in flutter and turning it into a pub package for use in other's projects

Since this is a work in progress, its important to first start with laying out the target and providing resources so that others can contribute. We can assume theres going to be math involved, and possible a need to write custom shaders.
I'd like to layout each individual concept such that it can be implemented incrementally with clear goals. 

My theory is that the core can be accomplished in 2 main steps -> get the background layer to the shader, and implement the shader rendering.

I've been experimenting and have achieved step 1 via BackdropFilter with imagefilter.shader - which appears to pass the image data to the shader automatically! Huge win. heres what that looks like so far:

<img src="https://github.com/user-attachments/assets/064b15a6-1d48-48f1-a4e3-a36802ff50ff" alt="Image" width="400">


### To-Do  
- [ ] Light Refraction - [Refraction in JS](https://www.youtube.com/watch?v=1LGa50gncgg)
  - [ ] Gyroscope changes light angle
  - [ ] prismatic edges 
  - [ ] Distortion of layer below
  - [ ] reflections of nearby content
  - [ ] caustics(could probably use water caustics type code, which if i remeber correctly can just be a texture png with perlin noise)
        
  <img src="https://github.com/user-attachments/assets/0ffb0f8c-ad8a-4a35-90d8-6b1d7e9f3bb0" width="300"/>
- [ ] Blurring
- [ ] Scale transitioning
- [ ] Color transition from transparent glass to solid color
- [ ] energizing touch
- [ ] Gel touch&drag

<img src="https://github.com/user-attachments/assets/1c32e8a3-f766-424b-823b-f7d970222f42" width="300"/>


- [ ] Nuemorphic like effects - these are typically easily done with clever use of inner and outer shadows. putting a lighter inner shadow color facing the light source, and a shadow on the opposite side you get a convex button. Inverting the shadows gives you concave(button press)
- [ ] Gooey Liquid / Surface tension pull effect. Save this for last as i dont think its all that important.[SDF RAYMARCHING](https://www.youtube.com/watch?v=5J-0sy2pu_8)

 <img src="https://github.com/user-attachments/assets/d03f71bd-356f-4004-bdff-98fec38fb8c9" width="300"/>



Parameter ideas
- [ ] blurStrength
- [ ] child widget
- [ ] borderRadius
- [ ] frostStrength appears to also determine degree of refraction
- [ ] appears to have a baseColor and animates between (its not simply changing immediately with the background layer)
- [ ] bezelWidth


If you need my immediate attention message me on [X](https://x.com/All4nDev)
