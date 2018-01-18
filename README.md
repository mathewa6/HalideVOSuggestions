HalideVOSuggestions
===


A project to test and prototype VoiceOver features to make leveling and focus states in video/photo apps clearer.

This version is altered for readability. The only file needed to understand whats going on is the main ViewController (AXOViewController). Please do read the comments at the top of the ViewController file for a detailed overview of this project. All implementation details can be viewed in the Supporting files group in Xcode.

## Notes

This prototype was used to test the following:

- Thickening of centered grid lines if VoiceOver (VO) is active
- Addition of audio tone when overlay grid is centered and VO is active
- (Usability) Increasing the threshold for decentering once a VO has centered the layout grid
- Slight change in hue of centered grid if environment lighting is bright (This should be changed to factor in color as well)

## Images

Here's a very rough approximation of the difference a slightly thicker centered grid makes.
![Grid Color](https://i.imgur.com/WbVXp1f.png)

Click the image below for a video showing the benefit of having a slight change in grid color over bright areas
[![Grid Color](https://i.imgur.com/Pv05hjo.png)](https://streamable.com/42h1w)


## License

None. 

This primarily to suggest changes that I think will help low vision users. The code is also largely untested and prioritized for readability.