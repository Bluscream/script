import subprocess
import shlex
from enum import auto, Flag, Enum

class SearchOptions(Enum):
    REGEX = "-r"
    CASE = "-i"
    WHOLE_WORD = "-w"
    MATCH_PATH = "-p"
    DIACRITICS = "-a"
    OFFSET = "-o"
    MAX_RESULTS = "-n"
    PATH = "-path"
    PARENT_PATH = "-parent-path"
    PARENT = "-parent"
    FOLDERS_ONLY = "/ad"
    FILES_ONLY = "/a-d"
    READ_ONLY = "/aR"
    HIDDEN = "/aH"
    SYSTEM = "/aS"
    DIRECTORY = "/aD"
    ARCHIVE = "/aA"
    DEVICE = "/aV"
    NORMAL = "/aN"
    TEMPORARY = "/aT"
    SPARSE_FILE = "/aP"
    REPARSE_POINT = "/aL"
    COMPRESSED = "/aC"
    OFFLINE = "/aO"
    NOT_CONTENT_INDEXED = "/aI"
    ENCRYPTED = "/aE"
    SORT_BY_PATH = "-s"
    SORT = "-sort"
    SORT_ASCENDING = "-sort-ascending"
    SORT_DESCENDING = "-sort-descending"
    NAME = "-name"
    PATH_COLUMN = "-path-column"
    FULL_PATH_AND_NAME = "-full-path-and-name"
    FILENAME_COLUMN = "-filename-column"
    EXTENSION = "-extension"
    SIZE = "-size"
    DATE_CREATED = "-date-created"
    DATE_MODIFIED = "-date-modified"
    DATE_ACCESSED = "-date-accessed"
    ATTRIBUTES = "-attributes"
    FILE_LIST_FILE_NAME = "-file-list-file-name"
    RUN_COUNT = "-run-count"
    DATE_RUN = "-date-run"
    DATE_RECENTLY_CHANGED = "-date-recently-changed"
    HIGHLIGHT = "-highlight"
    HIGHLIGHT_COLOR = "-highlight-color"
    CSV = "-csv"
    EFU = "-efu"
    TXT = "-txt"
    M3U = "-m3u"
    M3U8 = "-m3u8"
    TSV = "-tsv"
    SIZE_FORMAT = "-size-format"
    DATE_FORMAT = "-date-format"
    FILENAME_COLOR = "-filename-color"
    NAME_COLOR = "-name-color"
    PATH_COLOR = "-path-color"
    EXTENSION_COLOR = "-extension-color"
    SIZE_COLOR = "-size-color"
    DATE_CREATED_COLOR = "-date-created-color"
    DATE_MODIFIED_COLOR = "-date-modified-color"
    DATE_ACCESSED_COLOR = "-date-accessed-color"
    ATTRIBUTES_COLOR = "-attributes-color"
    FILE_LIST_FILENAME_COLOR = "-file-list-filename-color"
    RUN_COUNT_COLOR = "-run-count-color"
    DATE_RUN_COLOR = "-date-run-color"
    DATE_RECENTLY_CHANGED_COLOR = "-date-recently-changed-color"
    FILENAME_WIDTH = "-filename-width"
    NAME_WIDTH = "-name-width"
    PATH_WIDTH = "-path-width"
    EXTENSION_WIDTH = "-extension-width"
    SIZE_WIDTH = "-size-width"
    DATE_CREATED_WIDTH = "-date-created-width"
    DATE_MODIFIED_WIDTH = "-date-modified-width"
    DATE_ACCESSED_WIDTH = "-date-accessed-width"
    ATTRIBUTES_WIDTH = "-attributes-width"
    FILE_LIST_FILENAME_WIDTH = "-file-list-filename-width"
    RUN_COUNT_WIDTH = "-run-count-width"
    DATE_RUN_WIDTH = "-date-run-width"
    DATE_RECENTLY_CHANGED_WIDTH = "-date-recently-changed-width"
    NO_DIGIT_GROUPING = "-no-digit-grouping"
    SIZE_LEADING_ZERO = "-size-leading-zero"
    RUN_COUNT_LEADING_ZERO = "-run-count-leading-zero"
    DOUBLE_QUOTE = "-double-quote"
    EXPORT_CSV = "-export-csv"
    EXPORT_EFU = "-export-efu"
    EXPORT_TXT = "-export-txt"
    EXPORT_M3U = "-export-m3u"
    EXPORT_M3U8 = "-export-m3u8"
    EXPORT_TSV = "-export-tsv"
    NO_HEADER = "-no-header"
    UTF8_BOM = "-utf8-bom"
    HELP = "-h"
    INSTANCE = "-instance"
    IPC1 = "-ipc1"
    IPC2 = "-ipc2"
    PAUSE = "-pause"
    MORE = "-more"
    HIDE_EMPTY_SEARCH_RESULTS = "-hide-empty-search-results"
    EMPTY_SEARCH_HELP = "-empty-search-help"
    TIMEOUT = "-timeout"
    SET_RUN_COUNT = "-set-run-count"
    INC_RUN_COUNT = "-inc-run-count"
    GET_RUN_COUNT = "-get-run-count"
    GET_RESULT_COUNT = "-get-result-count"
    GET_TOTAL_SIZE = "-get-total-size"
    SAVE_SETTINGS = "-save-settings"
    CLEAR_SETTINGS = "-clear-settings"
    VERSION = "-version"
    GET_EVERYTHING_VERSION = "-get-everything-version"
    EXIT = "-exit"
    SAVE_DB = "-save-db"
    REINDEX = "-reindex"
    NO_RESULT_ERROR = "-no-result-error"

class AttributeSearch(Flag):
    R = auto()
    H = auto()
    S = auto()
    D = auto()
    A = auto()
    V = auto()
    N = auto()
    T = auto()
    P = auto()
    L = auto()
    C = auto()
    O = auto()
    I = auto()
    E = auto()

class EverythingSearch:
    everything_path:str
    options:str
    last_ran_command:str
    search_text:str
    paths:list[str]
    excluded_paths:list[str]


    def __init__(self, everything_path='es'):
        self.everything_path = everything_path
        self.options = ''
        self.last_ran_command = ''
        self.search_text = ''
        self.paths = []
        self.excluded_paths = []

    def _get_paths_str(self, paths:list[str] = None):
        if not paths: paths = self.paths
        return '-path ' + ' | '.join('\"\"\"'+path+'\"\"\"' for path in paths) if list(filter(None, paths)) else ''
    def _get_excluded_paths_str(self, excluded_paths:list[str] = None):
        if not excluded_paths: excluded_paths = self.excluded_paths
        return '!'+','.join("\""+path+"\"" for path in list(filter(None, excluded_paths))) if excluded_paths else ''

    def run(self, command):
        print("Running es command:",command)
        output = subprocess.check_output(command, shell=True) # , encoding='utf-8'
        self.last_ran_command = command
        return output.strip().split('\n')

    # C:\ !"C:\Windows,C:\Boot" 
    # command = f'es -size -s {" ".join([x for x in root_paths])} file:'
    #             es -size -path -path ""C:\"" | ""D:\"" !'C:\,D:\' ''
    #             es -size -path """C:\""" | """D:\""" "!'C:\Windows,C:\Boot' ''"
    #             es -size -path """C:\""" | """D:\""" "!"C:\Windows","C:\Boot" "
    #subprocess.CalledProcessError: Command 'es  -size -path """C:\""" | """D:\""" "!"C:\Windows","C:\Boot" "' returned non-zero exit status 255.
    def search(self, search_text:str=None, paths:list[str] = None, excluded_paths:list[str] = None):
        if not search_text: search_text = self.search_text
        if search_text: search_text = shlex.quote(search_text)
        if not paths: paths = self.paths
        if not excluded_paths: excluded_paths = self.excluded_paths
        command = f'{self.everything_path} {self.options} {self._get_paths_str()} "{self._get_excluded_paths_str()} {search_text}"'
        return self.run(command)

    def set_options(self, options):
        self.options = options

    def add_option(self, option):
        self.options += f' {option}'

    def remove_option(self, option):
        self.options = self.options.replace(option, '')

    def clear_options(self):
        self.options = ''

    def get_options(self):
        return self.options

    def get_help(self):
        command = f'{self.everything_path} -h'
        output = subprocess.check_output(command, shell=True, encoding='utf-8')
        return output.strip()
