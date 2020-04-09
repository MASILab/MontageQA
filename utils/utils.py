from tkinter import *
from datetime import datetime


class Window:
    # TODO: Add a prompt window asking for starter label file path
    # TODO: Add a label for displaying idx
    """
    The master tkinter window
    """
    def __init__(self, root, img_display):
        """
        Configure the master window.
        Enable full screen. The screen size is set to the maximum resolution of my machine's screen.
        Press Escape key to exit the program
        :param root: Tk()
        """
        self.root = root
        self.img_display = img_display
        self.root.title("Montage Labeler")
        self.root.geometry("1920x1080")
        self.root.attributes('-fullscreen', True)
        self.root.bind("<Escape>", exit)

    def exit(self, event):
        """
        Handler for exiting the program
        :param event: stub parameter required by tkinter keypress callback functions
        """
        print(event)
        self.root.destroy()


class ImageDisplay:
    """
    The core GUI: the canvas + all buttons
    """
    def __init__(self, root, img_file_name, table):
        """
        Set up the GUI layout.
        :param root: The master window.
        :param img_file_name: File path of the first image to be displayed
        :param table: Label table. A pandas data frame read from a csv file.
        """
        self.idx = 0
        self.table = table

        self.IMG_DIR = './images/'
        self.NUM_IMGS = len(self.table.index)
        self.OUT_FILE = './labels/labels_' + datetime.now().strftime("%m-%d-%Y %H_%M_%S") + '.csv'
        self.AUTO_SAVE_TIME = 10000  # Autosave every 10 seconds

        # Master frame - image + buttons for navigating directory
        self.master = Frame(root)

        # Master frame for all buttons + textbox
        self.right_margin = Frame(self.master)

        # TODO: Eliminate formatting numbers by packing them into a singleton

        # Labels for displaying idx
        self.idx_display = Label(self.right_margin, height=2, width=20, text=f"Montage #{self.idx + 1}")
        self.idx_display.pack(side=TOP)
        self.idx_display.config(font=("Courier", 15))

        # Textbox for displaying labels of current image
        self.label_display = Label(self.right_margin, height=2, width=20,
                                   text=f"[T:{table['taken out'][0]} G:{table['grainy'][0]} B:{table['broken'][0]}]")
        self.label_display.pack(side=TOP)
        self.label_display.config(font=("Courier", 20))

        # Buttons for navigating image directory
        self.image_buttons = Frame(self.right_margin, width=50, height=4)
        self.prev_image_button = Button(self.image_buttons, text='Previous Image', width=12,
                                        command=self.prev_image)
        self.next_image_button = Button(self.image_buttons, text='Next Image', width=12,
                                        command=self.next_image)

        # Arrange buttons
        self.prev_image_button.pack(side=LEFT)
        self.next_image_button.pack(padx=20, side=LEFT)
        self.image_buttons.pack(side=TOP)

        # Buttons for giving image labels
        self.label_buttons = Frame(self.right_margin)
        self.label_taken_button = Button(self.label_buttons, text='[T] Skull Taken out',
                                         command=self.label_skull_taken_out, width=14)
        self.label_grainy_button = Button(self.label_buttons, text='[G] Image Grainy',
                                          command=self.label_grainy, width=14)
        self.label_broken_button = Button(self.label_buttons, text='[B] Skull Broken',
                                          command=self.label_skull_broken, width=14)

        # Arrange buttons
        self.label_taken_button.pack(padx=5, side=LEFT)
        self.label_grainy_button.pack(padx=5, side=LEFT)
        self.label_broken_button.pack(padx=5, side=LEFT)
        self.label_buttons.pack(side=TOP, pady=20)

        # Button for saving labels
        self.label_save_button = Button(self.right_margin, text="S A V E", command=self.save)
        self.label_save_button.pack(side=TOP, pady=20, fill=BOTH)
        self.label_save_button.config(font=("Courier", 14))

        # Buttons for marking bad montage
        self.bad_clear_buttons = Frame(self.right_margin)
        self.bad_montage_button = Button(self.bad_clear_buttons, text="Bad Montage",
                                         width=12, command=lambda: self.update_all_labels(-1))
        self.clear_labels_button = Button(self.bad_clear_buttons, text="Clear Labels",
                                          width=12, command=lambda: self.update_all_labels(0))

        # Arrange buttons
        self.bad_montage_button.pack(side=LEFT, fill=BOTH)
        self.clear_labels_button.pack(side=LEFT, padx=20, fill=BOTH)
        self.bad_clear_buttons.pack(side=TOP, pady=20)

        # Input box and button for jumping to another image
        self.jump_to_image = Frame(self.right_margin)
        self.go_to_button = Button(self.jump_to_image, text="Go to: ", command=self.go_to_image)
        self.input_box = Entry(self.jump_to_image)

        # Arrange widgets
        self.go_to_button.pack(side=LEFT, padx=10)
        self.input_box.pack(side=LEFT, padx=10)
        self.jump_to_image.pack(side=TOP, pady=20)

        # Display for warning messages
        self.warning_message = Label(self.right_margin)
        self.warning_message.pack(side=TOP)

        self.right_margin.pack(side=RIGHT)

        # Canvas for displaying the image
        self.canvas = Canvas(self.master, width=1080, height=1080, bg='black')
        self.canvas.pack(side=LEFT)
        self.cur_img = PhotoImage(file=self.IMG_DIR + img_file_name)
        self.cur_img_id = self.canvas.create_image((0, 0), image=self.cur_img, anchor=NW)

        # Stub button for autosave
        self.autosave_button = Button(root)
        self.autosave_button.after(self.AUTO_SAVE_TIME, self.save)

        self.master.pack()

    def next_image(self):
        """
        Handler for when "Next Image" button is pressed.
        """
        if self.idx < self.NUM_IMGS - 1:
            self.idx = self.idx + 1
        else:
            self.idx = 0

        self._update_image()
        self._update_label_display()

    def prev_image(self):
        """
        Handler for when "Previous Image" button is pressed.
        """
        if self.idx > 0:
            self.idx = self.idx - 1
        else:
            self.idx = self.NUM_IMGS - 1

        self._update_image()
        self._update_label_display()

    # TODO: make these three methods more generic. Perhaps use some design patterns
    def label_skull_taken_out(self):
        """
        Handler for when "[T]Skull Taken Out" button is pressed.
        Toggle the label between 0 and 1. Update label text and self.table as well.
        """
        cur_label = self.table['taken out'][self.idx]

        if cur_label >= 0:
            # toggle between 0 and 1
            cur_label = 1 - cur_label

            self.table.iloc[self.idx, self.table.columns.get_loc('taken out')] = cur_label
            self._update_label_display()

    def label_grainy(self):
        """
        Handler for when "[G]Image Grainy" button is pressed.
        Toggle the label between 0 and 1. Update label text and self.table as well.
        """
        cur_label = self.table['grainy'][self.idx]

        if cur_label >= 0:
            # toggle between 0 and 1
            cur_label = 1 - cur_label

            self.table.iloc[self.idx, self.table.columns.get_loc('grainy')] = cur_label
            self._update_label_display()

    def label_skull_broken(self):
        """
        Handler for when "[B]Skull Broken" button is pressed.
        Toggle the label between 0 and 1. Update label text and self.table as well.
        """
        cur_label = self.table['broken'][self.idx]

        if cur_label >= 0:
            # toggle between 0 and 1
            cur_label = 1 - cur_label

            self.table.iloc[self.idx, self.table.columns.get_loc('broken')] = cur_label
            self._update_label_display()

    def save(self):
        """
        Write the content of self.table to disk every self.AUTO_SAVE_TIME milliseconds.
        """
        self.table.to_csv(self.OUT_FILE)
        # reschedule the autosave event
        self.autosave_button.after(self.AUTO_SAVE_TIME, self.save)

    def update_all_labels(self, val):
        """
        Update label text to val. Write the changes to self.table as well.
        :param val: the value that labels update to.
        """
        self.table.iloc[self.idx, self.table.columns.get_loc('taken out')] = val
        self.table.iloc[self.idx, self.table.columns.get_loc('grainy')] = val
        self.table.iloc[self.idx, self.table.columns.get_loc('broken')] = val
        self._update_label_display()

    def go_to_image(self):
        """
        Handler for when "Go to:" button is pressed.
        Verify user's entry in the input box is valid, then jump to the image
        """
        msg = f"Invalid input. Please enter an integer between 1 and {self.NUM_IMGS}."
        user_input = self.input_box.get()

        if not user_input.isnumeric():
            self.warning_message.config(text=msg)
        else:
            user_input = int(user_input)
            if user_input < 1 or user_input > self.NUM_IMGS:
                self.warning_message.config(text=msg)
            else:
                self.warning_message.config(text="")
                self.idx = user_input - 1
                self._update_image()
                self._update_label_display()

    def _update_image(self):
        """
        Update the image displayed on the canvas.
        """
        self.canvas.delete(self.cur_img_id)

        img_file_name = self.table["image path"][self.idx].replace('/', '+')
        img_file_name = self.IMG_DIR + img_file_name + ".png"
        self.cur_img = PhotoImage(file=img_file_name)
        self.cur_img_id = self.canvas.create_image((0, 0), image=self.cur_img, anchor=NW)

    def _update_label_display(self):
        """
        Update the label text to the content of the self.idx-th row of self.table.
        """
        self.label_display.config(text=f"[T:{self.table['taken out'][self.idx]} " +
                                       f"G:{self.table['grainy'][self.idx]} " +
                                       f"B:{self.table['broken'][self.idx]}]")
        self.idx_display.config(text=f"Montage #{self.idx + 1}")
