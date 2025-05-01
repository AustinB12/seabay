Must Have:
Visual Studio Code (or another code editor)
Flutter SDK
Dart SDK
Android Emulator or Physical Android Device

1. Download and Install Flutter SDK
Windows:
Go to the Flutter SDK website.

Download the Flutter SDK .zip file for Windows.

Extract the .zip file to a suitable location (e.g., C:\src\flutter).

Add the Flutter tool to your system PATH:

Open the Start menu, search for "Environment Variables", and select Edit the system environment variables.

Under System Variables, find and select the Path variable, click Edit, then New, and add the path to the flutter\bin directory (e.g., C:\src\flutter\bin).

Open a new terminal or command prompt and run:
flutter doctor
This will verify your setup and list any missing dependencies.

2. Download and Install Dart SDK
Note: The Dart SDK comes bundled with Flutter, so you typically don't need to install it separately if you're using Flutter.
If you do need Dart separately (for non-Flutter development):
Visit the Dart SDK download page.

Choose your platform (Windows, macOS, Linux) and follow the download instructions.

Add Dart to your system PATH similarly to how Flutter was added (you need the dart-sdk\bin path).

Run:
dart --version
	To check that Dart is properly installed.
3. Clone the Repository from GitHub
Using Git (Command Line):
Open a terminal or Git Bash.

Navigate to the folder where you want to clone the project:
cd path/to/your/folder
Run the following command to clone the repo:
git clone https://github.com/your-username/your-flutter-project.git
Navigate into the cloned directory:
cd your-flutter-project
Using GitHub Desktop:
Open GitHub Desktop.

Click on File > Clone Repository.

Select the repository from the list or paste the GitHub repo URL.

Choose the local path where the repo should be saved.

Click Clone.

Open the folder in Visual Studio Code (or right-click the folder and choose "Open with Code").
4. Install Android Emulator and Connect It to the Environment
Option A: Install Android Emulator via Android Studio
Download and install Android Studio from developer.android.com.

Open Android Studio > More Actions > SDK Manager.

Under the SDK Tools tab, check Android Emulator and click Apply.

Open Device Manager and create a Virtual Device (select a phone model and a system image like Pixel 5 + Android 13).

Click Play to launch the emulator.

Option B: Use a Physical Android Device
Enable Developer Mode and USB Debugging on your Android phone.

Connect your device via USB.

Run:
flutter devices
	to ensure the device is recognized.

5. Run the Application
Open the cloned Flutter project in Visual Studio Code.

In the terminal, make sure you're in the root folder of the Flutter project.

Run:
flutter pub get
	This installs all the required dependencies listed in pubspec.yaml.
Start your emulator or connect your device.
Then Run:
flutter run
The app should now compile and launch on the selected device.



Alternate Steps to Run the App (From a .zip File)
1. Unzip the Project Folder
Locate the .zip file you received.

Right-click and choose Extract All... (Windows) or Double-click to unzip (macOS).

Extract it to a preferred location (e.g., Desktop or C:\Projects\).

Open the extracted folder in Visual Studio Code or your preferred code editor.

2. Install Flutter and Dart SDK (if not already installed)
Follow the previously mentioned steps for installing Flutter and Dart SDKs, or refer to the Flutter installation guide.

3. Create a .env File in the Root Directory
In the root folder of the unzipped project (where pubspec.yaml is located), create a new file named:
.env
If using VS Code, right-click in the explorer panel and choose New File, then name it .env.
Add the following line to the file:
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFqamVjb3NtbnBwbnZ3b3BncGF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE5NjQ4MTgsImV4cCI6MjA1NzU0MDgxOH0.3z5wxn1clsaJkIl2iDFIrct6lFVh-H0dSqu8c-1GLmU
Save the file. Do not add quotes around the key, and make sure there’s no whitespace before or after the key.

4. Install Dependencies
Open a terminal in the project root (or use the built-in terminal in VS Code).

Run the following command to get the Flutter packages:
flutter pub get

5. Start an Android Emulator or Connect Your Device
Open Android Studio > Device Manager > Launch a virtual device, or

Plug in a physical Android device with USB Debugging enabled.

6. Run the App
Make sure your emulator or device is running.

In the terminal, run:
flutter run
The app should now build and launch. If your app reads the .env file using a package like flutter_dotenv, the SUPABASE_ANON_KEY will be available in your code.
