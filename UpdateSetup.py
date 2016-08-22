__author__ = 'Alexey Kostromin'

import os
import subprocess
from Tkinter import *
import glob, shutil
import fileinput

#from ttk import Frame, Button, Style, Label

DistrDir = "D:\\dev\\1c\\1CI\\Distr"
SetupDir = "D:\\dev\\1c\\1CI\\Setup"
ConfDir = "D:\\dev\\1c\\1CI\\"
ConfUser = "Administrator"
DemoDBUser = "Administrator"
RepDir = "D:\\dev\\1c\\1CI\\Repository"
RepUserName = "Administrator"
RepPassword = "123"
ConfPass = ""
DemoDBDir = "D:\\dev\\1c\\1CI\\Demo\\"
AppPath = "D:\\bin\\1cv83\\8.3.7.1873\\bin\\1cv8.exe"

def MakeDistr(lastReleaseDirName, nextReleaseDirName = None, update = False):

    if update:
        WorkingDir = DistrDir + "\\" + lastReleaseDirName
        nextReleaseDirName = lastReleaseDirName
    else:
        if lastReleaseDirName == nextReleaseDirName:
            print ("lastReleaseDirName and nextReleaseDirName are the same.")
            return False
        WorkingDir = DistrDir + "\\" + nextReleaseDirName

    #dump distr conf file
    try:
        subprocess.check_call([AppPath, 'DESIGNER', '/F', ConfDir, '/N' , ConfUser, '/CreateDistributionFiles','-cffile' , WorkingDir + '\\1Cv8.cf', '/ConfigurationRepositoryN' , RepUserName, '/ConfigurationRepositoryP' , RepPassword,'/ConfigurationRepositoryF' , RepDir], shell=False)
    except Exception as e:
        print ("Create distribution file error:  %s" % e)
        return False

    #update DemoDB
    try:
        subprocess.check_call([AppPath, 'DESIGNER', '/F', DemoDBDir , '/N', DemoDBUser, '/UpdateCfg', WorkingDir + '\\1Cv8.cf', '/UpdateDBCfg'], shell=False)
    except Exception as e:
        print "Update demo database error:" + e.message

	#Open Demo DB
    subprocess.call([AppPath, 'ENTERPRISE', '/F', DemoDBDir , '/N', DemoDBUser, '/UpdateCfg'], shell=False)

    #dump DemoDB archive
    try:
        subprocess.check_call([AppPath, 'DESIGNER', '/F', DemoDBDir ,'/N', DemoDBUser, '/DumpIB', WorkingDir + '\\1Cv8.dt'])
    except Exception as e:
        print "Making dump demo database archive error:" + e.message
        return False

    DistrPackagePath = DistrDir + "\\" + nextReleaseDirName + "\\DistributionPackage.edf"

    if update == False:
        files = glob.iglob(os.path.join(DistrDir + "\\" + lastReleaseDirName, "*.pdf"))
        for file in files:
            if os.path.isfile(file):
                shutil.copy2(file, DistrDir + "\\" + nextReleaseDirName)

        files = glob.iglob(os.path.join(DistrDir + "\\" + lastReleaseDirName, "*.epf"))
        for file in files:
            if os.path.isfile(file):
                shutil.copy2(file, DistrDir + "\\" + nextReleaseDirName)

        shutil.copyfile(DistrDir + "\\" + lastReleaseDirName + "\\DistributionPackage.edf", DistrPackagePath)
        f = open(DistrPackagePath,'r')
        filedata = f.read()
        f.close()

        newdata = filedata.replace(lastReleaseDirName,nextReleaseDirName)

        f = open(DistrPackagePath,'w')
        f.write(newdata)
        f.close()
    #CreateDistributive
    try:
        subprocess.check_call([AppPath, 'DESIGNER', '/F', ConfDir , '/N', ConfUser, '/ConfigurationRepositoryN' , RepUserName, '/ConfigurationRepositoryP' , RepPassword,'/ConfigurationRepositoryF' , RepDir, '/CreateDistributive', SetupDir, '-File', DistrPackagePath,'-MakeSetup'], shell=False)
    except Exception as e:
        print "Create distributive error:" + e.message
        return False

    return True

def FindLastReleaseDir():
    dirs = os.walk( os.path.join(DistrDir,'.')).next()[1]
    dirs.sort(reverse=True)
    if dirs.count > 0:
        return dirs[0]
    return ""

class App(Frame):
    def makeDistr(self):
        if MakeDistr(self.lastReleaseDirName.get(),self.nextReleaseDirName.get(), False if self.cbstate.get()==0 else True) == True:
           self.message["text"] = "Setup package was created."
           self.message["fg"] = "green"
           print("Setup package was created.")
        else:
           self.message["text"] = "Error!"
           self.message["fg"] = "red"
           print("Error!")
    def cb(self):
        if self.cbstate.get() == 0:
            self.nextReleaseEdit['state'] = NORMAL
        else:
            self.nextReleaseEdit['state'] = DISABLED

    def close_window(self):
         root.destroy()

    def createWidgets(self):

        self.lastReleaseDirName = StringVar()
        self.lastReleaseDirName.set(FindLastReleaseDir())

        self.nextReleaseDirName = StringVar()
        ver1, ver2, ver3, ver4 = str(self.lastReleaseDirName.get()).split('.')
        self.nextReleaseDirName.set(ver1 + '.' + ver2 + '.' + ver3 + "." + str(int(ver4)+1))

        self.parent.title("Setup package making")
#        self.style = Style()
#        self.style.theme_use("default")

        frame = Frame(self, relief=RAISED, borderwidth=1)
        frame.pack(fill=BOTH, expand=True)

        self.pack(fill=BOTH, expand=True)

        frame1 = Frame(frame)
        frame1.pack(fill=X, padx=5, pady=5)

        Label(frame1, text="Last release:", width=10).pack(side=LEFT, padx=5)

        self.lastReleaseEdit = Entry(frame1, textvariable = self.lastReleaseDirName)
        self.lastReleaseEdit.pack(fill=X, padx=5, expand=True)

        frame2 = Frame(frame)
        frame2.pack(fill=X, padx=5, pady=5)

        self.cbstate = IntVar()
        cb = Checkbutton(frame2, text = "update current", command=self.cb, variable=self.cbstate)
        cb.pack(fill=X, padx=5, expand=True);

        frame3 = Frame(frame)
        frame3.pack(fill=X, padx=5, pady=5)

        Label(frame3, text="Next release:", width=10).pack(side=LEFT, padx=5)
        self.nextReleaseEdit = Entry(frame3, textvariable = self.nextReleaseDirName)
        self.nextReleaseEdit.pack(fill=X, padx=5, expand=True)

        closeButton = Button(self, text="Close",command=self.close_window)
        closeButton.pack(side=RIGHT, padx=5, pady=5)
        okButton = Button(self, text="Run")
        okButton.pack(side=RIGHT)
        okButton["command"] = self.makeDistr

        frame4 = Frame(frame)
        frame4.pack(fill=X, padx=5, pady=5)
        self.message = Label(frame4, text="")
        self.message.pack(side=LEFT, padx=5)

    def __init__(self, parent=None):
        Frame.__init__(self, parent)
        self.parent = parent
        self.pack()
        self.createWidgets()

root = Tk()
root.geometry("300x170+300+300")

app = App(parent=root)
app.mainloop()
root.destroy()