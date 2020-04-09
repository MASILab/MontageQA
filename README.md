# MontageQA
A simple python GUI for labeling montages of nifti images. Written with [tkinter](https://wiki.python.org/moin/TkInter).

`label_nifti.m` is the MATLAB equivalence of the python GUI. It is slow, extremely unwieldy, and potentially buggy. I generally do not recommend using it.  
  
`label_montages.py` and files inside `/utils` are the actual python GUI.
  
## How To Use
1. Clone the repo. Inside `MontageQA` folder create two folders named `images` and `labels`.
  
2. Copy your montages to `./MontageQA/images`. If their dimensions are larger than 1080x1080 then parts of the montage might not be displayed.
  
3. Copy the spreadsheet for your labels to `./MontageQA`, i.e. the same directory as `label_montages.py`.
  
4. Change the line below in `label_montages.py` to the file name of your spreadsheet:
  ```python
  label_file = pd.read_csv('low_dose.csv', delimiter=',') # change this to the name of your own spreadsheet
  ```
5. Make sure that your spreadsheet contains a header with the following entries **in the exact order**: `image path`, `taken out`, `grainy`, `broken`.
  
6. Run `label_montages.py`. The application autosaves your progress every 10 seconds. Labels will be stored in `./MontageQA/labels` as a `.csv` file.
  
## Note
You may want to change this line in `./utils/utils.py`:
```python
img_file_name = self.table["image path"][self.idx].replace('/', '+')
```
and this line in `label_montages.py`:
```python
test_file_name = test_file_name.replace('/', '+') + '.png'
```
depending on your naming convention when you generate your montages:
  
## TODO
Get rid of the extra column when writting pandas dataframe to a `.csv` file. 
