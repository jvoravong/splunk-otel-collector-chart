#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import os
import re
import shutil
import subprocess
from glob import glob
from multiprocessing import Process

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
EXAMPLES_MAP = {}


# H_FILES_DIR = "c:\\Program Files\\blueCFD-Core-2016\\OpenFOAM-4.x\\src\\"
# DOC_FILES_DIR = '.' + os.sep


# FILE_LIST = (y for x in os.walk(SCRIPT_DIR)
#              for y in glob(os.path.join(x[0], '*.H')))

# def render_example_task(example_dir_path):
#   values_yaml = glob.glob(example_dir_path + '*-values.yaml')
#   rendered_manifests_dir = example_dir_path + ""
#   args = [
#   "helm template",
#   "--namespace default",
#   "--values" + values_yaml,
#   "--output-dir " + rendered_manifests_dir,
#   "default helm-charts/splunk-otel-collector"]
# normal = subprocess.run([external, arg],
#                         stdout=subprocess.PIPE, stderr=subprocess.PIPE,
#                         check=True,
#                         text=True)
#   print(normal.stdout)

def copy_and_overwrite(from_path, to_path):
  if os.path.exists(to_path):
    shutil.rmtree(to_path)
  shutil.copytree(from_path, to_path)

def render_examples():
  examples_md_file_path = SCRIPT_DIR + "/EXAMPLES.md"
  if os.path.exists(examples_md_file_path):
    os.remove(examples_md_file_path)

  example_values_files = glob(SCRIPT_DIR+'/*/*-values.yaml', recursive=True)
  for values_file in example_values_files:
    path_values_file = os.path.abspath(values_file)
    rendered_manifests_dir = os.path.abspath(os.path.dirname(
      values_file) + "/rendered_manifests")
    rendered_manifests_temp_dir = rendered_manifests_dir + "/splunk-otel-collector"
    print(path_values_file)
    print(rendered_manifests_dir)

    if os.path.exists(rendered_manifests_dir) and os.path.isdir(rendered_manifests_dir):
      shutil.rmtree(rendered_manifests_dir)

    args = [
      "helm", "template",
      "--namespace=default",
      "--values=" + values_file,
      # "--output-dir=" + rendered_manifests_dir,
      "default", "../helm-charts/splunk-otel-collector"]
    rendered_manifests_str = subprocess.run(
      args,
      stdout=subprocess.PIPE,
      stderr=subprocess.PIPE,
      check=True,
      text=True).stdout
    print(rendered_manifests_str)
    # shutil.copytree(
    #   rendered_manifests_dir + "/splunk-otel-collector/templates/",
    #   rendered_manifests_dir,
    #   dirs_exist_ok = True)
    #
    # if os.path.exists(rendered_manifests_temp_dir) and os.path.isdir(rendered_manifests_temp_dir):
    #   shutil.rmtree(rendered_manifests_temp_dir)
    EXAMPLES_MAP[values_file.split("/")[-1]] = rendered_manifests_str

  f = open(examples_md_file_path, "w")

  for example_name in EXAMPLES_MAP:
    s = """
<details close>
<summary>Example: %s</summary>
<pre><code>
%s
</code></pre>
</details>
  """ % (example_name, EXAMPLES_MAP[example_name])
    f.write(s)

  f.close()



  print(EXAMPLES_MAP)

def generate_examples_doc():
  example_values_files = glob(SCRIPT_DIR+'/*/*-values.yaml', recursive=True)
  for values_file in example_values_files:
    path_values_file = os.path.abspath(values_file)
    rendered_manifests_dir = os.path.abspath(os.path.dirname(
      values_file) + "/rendered_manifests")

# def GetFileHeaader(h_file):
#   with open(h_file) as f:
#     text_lines = f.readlines()
#
#   def match(s):
#     return True if '\*' and '*/\n' in s else False
#
#   doc_begin = filter(lambda x: 'Class\n' in x[1], enumerate(text_lines))
#   doc_end = filter(lambda x: match(x[1]), enumerate(text_lines))
#
#   if doc_begin and doc_end:
#     return text_lines[doc_begin[0][0]:doc_end[0][0]]
#   else:
#     return
#
#
# def _mkdir_recursive(path):
#   sub_path = os.path.dirname(path)
#   if not os.path.exists(sub_path):
#     _mkdir_recursive(sub_path)
#   if not os.path.exists(path):
#     os.mkdir(path)
#
#
# def _format_MARKDOWN(text):
#   for line, line_text in enumerate(text):
#     if line_text == '\n':
#       continue
#     if line_text[0] != ' ':
#       text[line] = '## %s' % line_text
#       continue
#     if '    ' in line_text and '     ' not in line_text:
#       text[line] = line_text.replace('    ', '')
#     if 'erbatim\n' in line_text:
#       text[line] = '```\n'
#       continue
#     if '\\table' in line_text:
#       text[line] = '\n'
#       continue
#     if '\endtable' in line_text:
#       text[line] = '\n'
#       continue
#     # if line_text.count('|'):
#     #     text[line] = '|' + % line_text
#
#     # if '<a href=' in line_text:
#     #     text[line] = line_text.replace('<a href=', '[')
#     #     continue
#     # if '<\a>' in line_text:
#     #     text[line] = line_text.replace('</a>', ']')
#     #     continue
#
#   return text
#
#
# for h_file in FILE_LIST:
#   def _file(the_file):
#     return os.path.split(os.path.abspath(the_file))
#
#
#   doc_text = GetFileHeaader(h_file)
#   DOC_FILE = _file(h_file.replace(H_FILES_DIR, DOC_FILES_DIR))
#
#   if doc_text:
#     _mkdir_recursive(DOC_FILE[0])
#     with open(os.sep.join(DOC_FILE).replace('.H', '.md'), 'w') as f:
#       _format_MARKDOWN(doc_text)
#       doc_text.insert(0, '# %s \n' % DOC_FILE[1].replace('.H', ''))
#       f.writelines(doc_text)
#
# MD_FILE_LIST = (y for x in os.walk(DOC_FILES_DIR)
#                 for y in glob(os.path.join(x[0], '*.md')))
#
# with open(DOC_FILES_DIR + 'README.md', 'w') as f:
#   text = []
#   for m_file in MD_FILE_LIST:
#     levels = m_file.replace(DOC_FILES_DIR, '').count(os.sep)
#     if levels < 3:
#       text.append(' * ' + '#' * levels + ' [%s](./%s)\n\n' %
#                   (m_file.split(os.sep)[-1].replace('.md', ''),
#                    m_file.replace(DOC_FILES_DIR, '').replace(os.sep, '/')))
#
#     else:
#       text.append('%s[%s](./%s)\n\n' % (' ' * levels + '- ',
#                                         m_file.split(os.sep)[-1].replace('.md',
#                                                                          ''),
#                                         m_file.replace(DOC_FILES_DIR,
#                                                        '').replace(os.sep,
#                                                                    '/')))
#   text[0] = "# Index\n\n"
#   f.writelines(text)
#
# # print ':: Done ::'

render_examples()
