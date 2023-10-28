
def install():
    if not os.path.exists(f"{os.getcwd()}/config.txt"):
        with open(f"{os.getcwd()}/config.txt", "w") as config:
            config.write("scrap mechanic file path = C:\Program Files (x86)\Steam\steamapps\common\Scrap Mechanic")
        print("config.txt not found generating new config.txt")

    print("config.txt found")
    with open(f"{os.getcwd()}/config.txt","r") as config:
        path = config.read()
        print(path)
        path = path.split(" = ")[1]
        print(f"Looking for Scrap Mechanic at {path}")

    if not os.path.exists(path):
        print("Unable to find Scrap Mechanic please check config file")
        return

    print("Scrap Mechanic files found")
    if os.path.exists(f"{os.getcwd()}/temp"):
        git.rmtree(f"{os.getcwd()}/temp")
    print("Downloading files")
    repo = git.Repo.clone_from('https://github.com/Masterang3rfi/sm_sbeveco.git',f"{os.getcwd()}/temp")
    git.rmtree(f"{os.getcwd()}/temp/.git")
    print("Download complete")

    print("Installing files")
    root_src_dir = f"{os.getcwd()}/temp"
    root_dst_dir = path

    for src_dir, dirs, files in os.walk(root_src_dir):
        dst_dir = src_dir.replace(root_src_dir, root_dst_dir, 1)
        if not os.path.exists(dst_dir):
            os.makedirs(dst_dir)
        for file_ in files:
            src_file = os.path.join(src_dir, file_)
            dst_file = os.path.join(dst_dir, file_)
            if os.path.exists(dst_file):
                # in case of the src and dst are the same file
                if os.path.samefile(src_file, dst_file):
                    continue
                os.remove(dst_file)
            shutil.move(src_file, dst_dir)

    print("Install complete")



if __name__ == "__main__":
    try:
        import pip
        import os
        import shutil
        pip_modules = ["Gitpython","traceback-with-variables"]
        modules= ["git", "traceback"]
        for i in range(len(modules)):
            try:
                __import__(modules[i])
            except ImportError as e:
                print(e)
                pip.main(['install', pip_modules[i]])
        import git
        import traceback
        try:
            install()
            input("Press Enter to close")
        except:
            traceback.print_exc()
    except Exception as e:
        print(e)
        input("Press Enter to close")