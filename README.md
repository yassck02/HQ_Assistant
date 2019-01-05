# HQ_Assistant

A tool/bot to *assist* users with the (once) popular mobile phone trivia game

|                                       |                                       |
|                  :---:                |                   :---:               |
| ![img00001.png](/images/img00001.png) | ![img00002.png](/images/img00002.png) |
|                                       |                                       |

### Tools + Frameworks
- Xcode
- OCR API (https://api.ocr.space/parse/image()

### Background
HQ is a mobile trivia game in which participants are asked a seriese of 12 (or sometimes more) multiple choice trivia questions. if they survive all the questions, they split a cash prize with the other (if any) remaining winners. Currently there are 2 games every day at 1pm ang 9pm.

### How it works
- A screenshot of the question is taken
- The text (the question and choices) is extracted from the image using optical character recognition software
- The question is then searched on google using multiple different methods (API call, raw link search and html parse)
- The results are analyzed multiple different ways and a suggested answer is presented to the user - all in a matter of milliseconds.

Depending on the type of the question, up to nearly a hundred different google searches can pe performed on a variety of terms including the question itself, each of the search terms, and keywords from the question. The results are then cross referenced with eachother: eg if the question was searched, count the optinos in the result, if the option was searched, search for the questions keywords in the results.
Depending on the type of cross reference, certain hits have different weights. The weights are then summed for each choice and the chioce with the highest is suggested as the answer.

A number of special cases exist. Questions that ask "Which/who of these is not..." are simply inverted. The choice with the lowest weight is suggested as the answer.

Unfortunately the HQ app was updated to automaticaly close if it detects your device's screen being mirrored. A simple workaround could be to 'mirror' your iDevices screen to the desktop using a webcam.

### Related Links
- https://en.wikipedia.org/wiki/HQ_Trivia
- https://itunes.apple.com/us/app/hq-trivia-words/id1232278996?mt=8