# Reader
一个轻量的iOS阅读器，支持自动分章分页，更改字号，记录进度等功能。
支持txt和epub格式，打开文件后首次会读取全本内容然后分章，然后归档，然后按需对当前/前一/后一章节进行分页，
非首次打开同一文件，会从沙盒目录直接读取解档分章的数据结构，在进行分页，性能良好。
