global check;
check = struct();
src = char(fileread(mfilename("fullpathext")));
eval(strsplit(src,["# =L=I=B=R" "=A=R=Y=@="]){2});


file_parts = extract_parts(src);
check_initialize(file_parts);
{% load i18n %}
# NE BRIŠI prvih vrstic

# =============================================================================
# {{ problem.title|safe }}{% if problem.description %}
#
# {{ problem.description|indent:"# "|safe }}{% endif %}{% for part in problem.parts.all %}
# =====================================================================@{{ part.id|stringformat:'06d'}}=
# {{ part.description|indent:"# "|safe }}
# =============================================================================
{{ part.solution|safe }}

check_part()
{{ part.validation|safe }}

{% endfor %}
# # =====================================================================@000000=
# # {% blocktrans %}  This is a template for a new problem part. To create a new part, uncomment
# # the template and fill in your content.
# #
# # Define a function `multiply(x, y)` that returns the product of `x` and `y`.
# # For example:
# #
# #     octave> multiply(3, 7)
# #     ans = 21
# #     octave> multiply(6, 7)
# #     ans = 42{% endblocktrans %}
# # =============================================================================
#
# function p = {% trans "multiply" %}(x, y)
#     p =  x * y
# endfunction
#
# check_part()
#
# check_equal('{% trans "multiply" %}(3, 7)', 21)
# check_equal('{% trans "multiply" %}(6, 7)', 42)
# check_equal('{% trans "multiply" %}(10, 10)', 100)
# check_secret({% trans "multiply" %}(100, 100))
# check_secret({% trans "multiply" %}(500, 123))


# ===========================================================================@=
# {% trans "Do not change this line or anything below it." %}
# =============================================================================

validate_current_file(src,check.parts);

# =L=I=B=R=A=R=Y=@=

'Če vam Octave sporoča, da je v tej vrstici sintaktična napaka,';
'se napaka v resnici skriva v zadnjih vrsticah vaše kode.';

'Kode od tu naprej NE SPREMINJAJTE!';

# check.m
{% include 'octave/check_functions.m' %}
# check.m
# varargin2struct.m
{% include 'octave/jsonlab.m' %}

{% include 'octave/utils.m' %}

function validation = validate_current_file(src,parts)
#    def backup(filename):
#        backup_filename = None
#        suffix = 1
#        while not backup_filename or os.path.exists(backup_filename):
%            backup_filename = '{0}.{1}'.format(filename, suffix)
%            suffix += 1
%        shutil.copy(filename, backup_filename)
%        return backup_filename
%
%
 # split solution to solution and validation
  n = length(parts);
  valid = [];
  for i=1:n
    parts{i}.problem = {{ problem.id }};
    parts{i}.solution = parts{i}.solution;
    parts{i}.validation = parts{i}.validation;
    if str2num(parts{i}.part) != 0
      parts{i}.id = str2num(parts{i}.part);
    end
    valid  = [valid parts{i}.valid];
    parts{i} = rmfield(rmfield(rmfield(parts{i},'valid'),'feedback'),'part');
  end
  problem_regex = ['# =+\n',...                      # beginning of header
      '# (?<title>[^\n]*)\n',...              # title
      '(?<description>(#( [^\n]*)?\n)*)',...  # description
      '(?=(# )?# =+@)',];                     # beginning of first part
  [s, e, te, m, t, nm, sp] = regexp(src,problem_regex,'dotall');
  problem = struct(
    "parts",{parts},
    "title",strtrim(nm.title),
    "description",regexprep(strtrim(nm.description),'^#','','lineanchors'),
    "id", {{ problem.id }},
    "problem_set", {{ problem.problem_set.id }}
  );
  if all(valid)
    shranim = input("Ali rešitve shranim na strežnik? (da/ne) ","s");
    if strtrim(shranim) == "da"
      printf('Shranjujem rešitve na strežnik... ');
      url = "{{ submission_url }}"; #'https://www.projekt-tomo.si/api/attempts/submit/';
      token = "Token {{ authentication_token }}"; #'Token 0779d82c83d98c1e4a5480e4e6f57b906598f5ee';
      response = submit_parts(problem, url, token);
    end
  else
    disp("Problem ni dobro formuliran!");
  end
  check_summarize()
endfunction

# attempt.m
