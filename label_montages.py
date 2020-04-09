import pandas as pd
from utils.utils import *

label_file = pd.read_csv('low_dose.csv', delimiter=',')
test_file_name = label_file['image path'][0]
test_file_name = test_file_name.replace('/', '+') + '.png'

root = Tk()
window = Window(root, ImageDisplay(root, test_file_name, label_file))
root.mainloop()
