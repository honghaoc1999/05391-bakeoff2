import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Random;
import java.util.HashMap;
import java.util.SortedMap;
import java.util.Comparator;
import org.apache.commons.collections4.trie.PatriciaTrie;

public class TrieNode {
    private HashMap<Character, TrieNode> children;
    private String content;
    private boolean isWord;
}

String[] phrases; //contains all of the phrases
int totalTrialNum = 2; //the total number of phrases to be tested!
int currTrialNum = 0; // the current trial number (indexes into trials array above)
float startTime = 0; // time starts when the first letter is entered
float finishTime = 0; // records the time of when the final trial ends
float lastTime = 0; //the timestamp of when the last trial was completed
float lettersEnteredTotal = 0; //a running total of the number of letters the user has entered (need this for final WPM computation)
float lettersExpectedTotal = 0; //a running total of the number of letters expected (correct phrases)
float errorsTotal = 0; //a running total of the number of errors (when hitting next)
String currentPhrase = ""; //the current target phrase
String currentTyped = ""; //what the user has typed so far
final int DPIofYourDeviceScreen = 200; //you will need to look up the DPI or PPI of your device to make sure you get the right scale!!
//http://en.wikipedia.org/wiki/List_of_displays_by_pixel_density
final float sizeOfInputArea = DPIofYourDeviceScreen*1; //aka, 1.0 inches square!
PImage watch;
final int suggestTopN = 4;

PatriciaTrie trie = new PatriciaTrie<>();

//Variables for my silly implementation. You can delete this:
char currentLetter = 'a';
String currentWord = "";
List<String> typedWords = new ArrayList();
List<String> suggestTopNWords = new ArrayList();

ArrayList<String> keyboardLetters = new ArrayList<String>(
  Arrays.asList("q", "w", "e", "r", "t", "y", "u", "i", "o", "p", 
                "a", "s", "d", "f", "g", "h", "j", "k", "l",
                "z", "x", "c", "v", "b", "n", "m")
);

void populateTrie(List<String> phrases) {
  for (String sent : phrases) {
    String words[] = sent.split(" ");
    for(String word: words) {
      trie.put(word, word);
    }
  }
}

void simpleTrieTest() {
  print(trie.prefixMap("preva"));
  print(trie.prefixMap("sat"));
}

//You can modify anything in here. This is just a basic implementation.
void setup()
{
  watch = loadImage("watchhand3smaller.png");
  phrases = loadStrings("phrases2.txt"); //load the phrase set into memory
  populateTrie(Arrays.asList(phrases));
  Collections.shuffle(Arrays.asList(phrases), new Random()); //randomize the order of the phrases with no seed
  //Collections.shuffle(Arrays.asList(phrases), new Random(100)); //randomize the order of the phrases with seed 100; same order every time, useful for testing
  orientation(LANDSCAPE); //can also be PORTRAIT - sets orientation on android device
  size(800, 800); //Sets the size of the app. You should modify this to your device's native size. Many phones today are 1080 wide by 1920 tall.
  textFont(createFont("Arial", 24)); //set the font to arial 24. Creating fonts is expensive, so make difference sizes once in setup, not draw
  noStroke(); //my code doesn't use any strokes
}

void drawSuggestWords() {
  textAlign(CENTER, CENTER);
  int numSuggestWords = min(suggestTopN, suggestTopNWords.size());
  if (numSuggestWords <= 2) {
    for (int i = 0; i < numSuggestWords; i++) {
      fill(0, 255, 255); //cyan suggest words background
      stroke(204, 102, 0);
      rect(width/2-sizeOfInputArea/2+(sizeOfInputArea / suggestTopNWords.size() * i), height/2-sizeOfInputArea/2 + 40, sizeOfInputArea / numSuggestWords, 40);
      fill(0, 0, 0); // black suggest texts
      text(suggestTopNWords.get(i), width/2-sizeOfInputArea/2+(sizeOfInputArea / suggestTopNWords.size() * i) + sizeOfInputArea / numSuggestWords / 2, height/2-sizeOfInputArea/2 + 40 + 17);
    }
  }
  else {
    for (int i = 0; i < numSuggestWords; i++) {
      if (i < 2) {
        fill(0, 255, 255); //cyan suggest words background
        stroke(204, 102, 0);
        rect(width/2-sizeOfInputArea/2+(sizeOfInputArea / 2 * i), height/2-sizeOfInputArea/2 + 40, sizeOfInputArea / 2, 40);
        fill(0, 0, 0); // black suggest texts
        text(suggestTopNWords.get(i), width/2-sizeOfInputArea/2+(sizeOfInputArea / 2 * i) + sizeOfInputArea / 2 / 2, height/2-sizeOfInputArea/2 + 40 + 17);
      }
      else {
        fill(0, 255, 255); //cyan suggest words background
        stroke(204, 102, 0);
        rect(width/2-sizeOfInputArea/2+(sizeOfInputArea / (suggestTopNWords.size() - 2) * (i - 2)), height/2-sizeOfInputArea/2, sizeOfInputArea / (numSuggestWords - 2), 40);
        fill(0, 0, 0); // black suggest texts
        text(suggestTopNWords.get(i), width/2-sizeOfInputArea/2+(sizeOfInputArea / (suggestTopNWords.size() - 2) * (i - 2)) + sizeOfInputArea / (numSuggestWords - 2) / 2, height/2-sizeOfInputArea/2 + 17);
      }
    }
  }
  stroke(0);
}

//You can modify anything in here. This is just a basic implementation.
void draw()
{
  background(255); //clear background
  drawWatch(); //draw watch background
  fill(100);
  rect(width/2-sizeOfInputArea/2, height/2-sizeOfInputArea/2, sizeOfInputArea, sizeOfInputArea); //input area should be 1" by 1"

  if (finishTime!=0)
  {
    fill(128);
    textAlign(CENTER);
    text("Finished", 280, 150);
    return;
  }

  if (startTime==0 & !mousePressed)
  {
    fill(128);
    textAlign(CENTER);
    text("Click to start time!", 280, 150); //display this messsage until the user clicks!
  }

  if (startTime==0 & mousePressed)
  {
    nextTrial(); //start the trials!
  }

  if (startTime!=0)
  {
    //feel free to change the size and position of the target/entered phrases and next button 
    textAlign(LEFT); //align the text left
    fill(128);
    text("Phrase " + (currTrialNum+1) + " of " + totalTrialNum, 70, 50); //draw the trial count
    fill(128);
    text("Target:   " + currentPhrase, 70, 100); //draw the target string
    text("Entered:  " + currentTyped +"|", 70, 140); //draw what the user has entered thus far 

    //draw very basic next button
    fill(255, 0, 0);
    rect(600, 600, 200, 200); //draw next button
    fill(255);
    text("NEXT > ", 650, 650); //draw next label
    
    // V3 keyboard
    fill(255, 255, 255); //text buttons color
    textAlign(CENTER, CENTER);
    for (int i = 0; i < keyboardLetters.size(); i++) {
      if (i < 10) { // first row of text buttons
        fill(255, 255, 255);
        print(sizeOfInputArea,"\n");
        stroke(204, 102, 0);
        rect((int)(width/2-sizeOfInputArea/2 + 20 * i), (int)(height/2-sizeOfInputArea/2 + 80), 20, 30);
        fill(0, 0, 0);
        textSize(20);
        text(keyboardLetters.get(i), (int)(width/2-sizeOfInputArea/2 + 20 * i + 10), height/2-sizeOfInputArea/2 + 80+10);
      }
      else if (i < 19) { // second row of text buttons
        fill(255, 255, 255);
        print(sizeOfInputArea,"\n");
        stroke(204, 102, 0);
        rect((int)(width/2-sizeOfInputArea/2 + 20 * (i - 10)), (int)(height/2-sizeOfInputArea/2 + 110), 20, 30);
        fill(0, 0, 0);
        textSize(20);
        text(keyboardLetters.get(i), (int)(width/2-sizeOfInputArea/2 + 20 * (i - 10) + 10), height/2-sizeOfInputArea/2 + 110+13);
      }
      else { // third row text buttons
        fill(255, 255, 255);
        print(sizeOfInputArea,"\n");
        stroke(204, 102, 0);
        rect((int)(width/2-sizeOfInputArea/2 + 20 * (i - 19)), (int)(height/2-sizeOfInputArea/2 + 140), 20, 30);
        fill(0, 0, 0);
        textSize(20);
        text(keyboardLetters.get(i), (int)(width/2-sizeOfInputArea/2 + 20 * (i - 19) + 10), height/2-sizeOfInputArea/2 + 140+13);
      }
    }
    fill(255, 255, 255);
    rect(width/2-sizeOfInputArea/2, (int)(height/2-sizeOfInputArea/2 + 170), 140, 30); // space button
    fill(0, 0, 0);
    text("space", width/2-sizeOfInputArea/2 + 70, height/2-sizeOfInputArea/2 + 170+12);
    fill(255, 255, 255);
    rect(width/2-sizeOfInputArea/2 + 140, (int)(height/2-sizeOfInputArea/2) + 140, 60, 60); // delete button
    fill(0, 0, 0);
    text("delete", width/2-sizeOfInputArea/2 + 140 + 30, (int)(height/2-sizeOfInputArea/2) + 140 + 30); 
    drawSuggestWords();
  }
}

void printPrefixMap() {
  SortedMap<String, String> prefixMap = trie.prefixMap(currentWord);
  if (currentWord.length() > 0) {
    println(prefixMap);
  }
  else {
    println("currentWord empty");
    suggestTopNWords.clear();
    return;
  }
  // Get shortest N words to show
  List<String> matchedWords = new ArrayList<>(prefixMap.values());
  Collections.sort(matchedWords, Comparator.comparing(String::length));
  suggestTopNWords.clear();
  for (int i = 0; i < min(suggestTopN, matchedWords.size()); i++) {
    suggestTopNWords.add(matchedWords.get(i));
  }
}

//my terrible implementation you can entirely replace
boolean didMouseClick(float x, float y, float w, float h) //simple function to do hit testing
{
  return (mouseX > x && mouseX<x+w && mouseY>y && mouseY<y+h); //check to see if it is in button bounds
}

String didMouseClickLetter() {
  for (int i = 0; i < keyboardLetters.size(); i++) {
    if (i < 10) { // first row of text buttons
      if (didMouseClick((width/2-sizeOfInputArea/2 + 20 * i), (int)(height/2-sizeOfInputArea/2 + 80), 20, 30))
        return keyboardLetters.get(i);
    }
    else if (i < 19) { // second row of text buttons
      if (didMouseClick((int)(width/2-sizeOfInputArea/2 + 20 * (i - 10)), (int)(height/2-sizeOfInputArea/2 + 110), 20, 30))
        return keyboardLetters.get(i);
    }
    else { // third row text buttons
      if (didMouseClick(width/2-sizeOfInputArea/2 + 20 * (i - 19), (int)(height/2-sizeOfInputArea/2 + 140), 20, 30))
        return keyboardLetters.get(i);
    }
  }
  return "";
}

void SuggestWordClicked(int i) {
  currentTyped = currentTyped.substring(0, currentTyped.length() - currentWord.length());
  currentWord = ""; // auto 
  currentTyped += suggestTopNWords.get(i) + " ";
  typedWords.add(suggestTopNWords.get(i));
  print("clicked suggested");
}

void handleSuggestWordClick() {
  int numSuggestWords = min(suggestTopN, suggestTopNWords.size());
  if (numSuggestWords <= 2) {
    for (int i = 0; i < numSuggestWords; i++) {
      if (didMouseClick(width/2-sizeOfInputArea/2+(sizeOfInputArea / suggestTopNWords.size() * i), height/2-sizeOfInputArea/2 + 40, sizeOfInputArea / numSuggestWords, 40)) {
        SuggestWordClicked(i);
      }
    }
  }
  else {
    for (int i = 0; i < numSuggestWords; i++) {
      if (i < 2) {
        if (didMouseClick(width/2-sizeOfInputArea/2+(sizeOfInputArea / 2 * i), height/2-sizeOfInputArea/2 + 40, sizeOfInputArea / 2, 40)) {
          SuggestWordClicked(i);
        }
      }
      else {
        if (didMouseClick(width/2-sizeOfInputArea/2+(sizeOfInputArea / (suggestTopNWords.size() - 2) * (i - 2)), height/2-sizeOfInputArea/2, sizeOfInputArea / (numSuggestWords - 2), 40)) {
          SuggestWordClicked(i);
        }
      }
    }
  }
}

//my terrible implementation you can entirely replace
void mousePressed()
{
  if (didMouseClick(width/2-sizeOfInputArea/2 + 140, (int)(height/2-sizeOfInputArea/2) + 140, 60, 60)) //check if click in backspace button
  {
    if (currentTyped.length() > 0) // delete a letter if anything was typed in this trial
      currentTyped = currentTyped.substring(0, currentTyped.length()-1);
    if (currentWord.length() > 0) { // delete a letter from currentWord if currentWord not empty
      currentWord = currentWord.substring(0, currentWord.length() - 1);
    }
    else { // if currentWord is already empty, will restore currentWord to last complete word if there is any
      if (typedWords.size() > 0) {
        currentWord = typedWords.remove(typedWords.size() - 1);
      }
    }
    printPrefixMap();
  }
  String clickedLetter = didMouseClickLetter();
  if (clickedLetter.length() > 0) {
    currentTyped += clickedLetter;
    currentWord += clickedLetter;
    printPrefixMap();
  }
  // handles click on space button 
  if (didMouseClick(width/2-sizeOfInputArea/2, (int)(height/2-sizeOfInputArea/2 + 170), 140, 30)) {
    currentTyped+=" ";
    try {
      typedWords.add(currentWord);
    }
    catch (Exception e) {
      print(e);
      print(typedWords);
      print(currentWord);
    }
    
    currentWord = ""; // clean current word since we start a new one
    printPrefixMap();
  }

  handleSuggestWordClick();

  //You are allowed to have a next button outside the 1" area
  if (didMouseClick(600, 600, 200, 200)) //check if click is in next button
  {
    nextTrial(); //if so, advance to next trial
  }
}


void nextTrial()
{
  if (currTrialNum >= totalTrialNum) //check to see if experiment is done
    return; //if so, just return

  if (startTime!=0 && finishTime==0) //in the middle of trials
  {
    System.out.println("==================");
    System.out.println("Phrase " + (currTrialNum+1) + " of " + totalTrialNum); //output
    System.out.println("Target phrase: " + currentPhrase); //output
    System.out.println("Phrase length: " + currentPhrase.length()); //output
    System.out.println("User typed: " + currentTyped); //output
    System.out.println("User typed length: " + currentTyped.length()); //output
    System.out.println("Number of errors: " + computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim())); //trim whitespace and compute errors
    System.out.println("Time taken on this trial: " + (millis()-lastTime)); //output
    System.out.println("Time taken since beginning: " + (millis()-startTime)); //output
    System.out.println("==================");
    lettersExpectedTotal+=currentPhrase.trim().length();
    lettersEnteredTotal+=currentTyped.trim().length();
    errorsTotal+=computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim());
  }

  //probably shouldn't need to modify any of this output / penalty code.
  if (currTrialNum == totalTrialNum-1) //check to see if experiment just finished
  {
    finishTime = millis();
    System.out.println("==================");
    System.out.println("Trials complete!"); //output
    System.out.println("Total time taken: " + (finishTime - startTime)); //output
    System.out.println("Total letters entered: " + lettersEnteredTotal); //output
    System.out.println("Total letters expected: " + lettersExpectedTotal); //output
    System.out.println("Total errors entered: " + errorsTotal); //output

    float wpm = (lettersEnteredTotal/5.0f)/((finishTime - startTime)/60000f); //FYI - 60K is number of milliseconds in minute
    float freebieErrors = lettersExpectedTotal*.05; //no penalty if errors are under 5% of chars
    float penalty = max(errorsTotal-freebieErrors, 0) * .5f;
    
    System.out.println("Raw WPM: " + wpm); //output
    System.out.println("Freebie errors: " + freebieErrors); //output
    System.out.println("Penalty: " + penalty);
    System.out.println("WPM w/ penalty: " + (wpm-penalty)); //yes, minus, becuase higher WPM is better
    System.out.println("==================");

    currTrialNum++; //increment by one so this mesage only appears once when all trials are done
    return;
  }

  if (startTime==0) //first trial starting now
  {
    System.out.println("Trials beginning! Starting timer..."); //output we're done
    startTime = millis(); //start the timer!
  } 
  else
    currTrialNum++; //increment trial number

  lastTime = millis(); //record the time of when this trial ended
  currentTyped = ""; //clear what is currently typed preparing for next trial
  currentWord = ""; //clear current word for next trial
  currentPhrase = phrases[currTrialNum]; // load the next phrase!
  //currentPhrase = "abc"; // uncomment this to override the test phrase (useful for debugging)
}


void drawWatch()
{
  float watchscale = DPIofYourDeviceScreen/138.0;
  pushMatrix();
  translate(width/2, height/2);
  scale(watchscale);
  imageMode(CENTER);
  image(watch, 0, 0);
  popMatrix();
}





//=========SHOULD NOT NEED TO TOUCH THIS METHOD AT ALL!==============
int computeLevenshteinDistance(String phrase1, String phrase2) //this computers error between two strings
{
  int[][] distance = new int[phrase1.length() + 1][phrase2.length() + 1];

  for (int i = 0; i <= phrase1.length(); i++)
    distance[i][0] = i;
  for (int j = 1; j <= phrase2.length(); j++)
    distance[0][j] = j;

  for (int i = 1; i <= phrase1.length(); i++)
    for (int j = 1; j <= phrase2.length(); j++)
      distance[i][j] = min(min(distance[i - 1][j] + 1, distance[i][j - 1] + 1), distance[i - 1][j - 1] + ((phrase1.charAt(i - 1) == phrase2.charAt(j - 1)) ? 0 : 1));

  return distance[phrase1.length()][phrase2.length()];
}
