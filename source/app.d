import bindbc.glfw;
import bindbc.opengl;
import std.stdio;
import std.string;

static GLfloat[6] VERTEX_DATA = [0.0, 0.5, 0.5, -0.5, -0.5, -0.5];

string VS_SRC = `
#version 150
in vec2 position;

void main()
{
    gl_Position = vec4(position, 0.0, 1.0);
}`;

string FS_SRC = `
#version 150
out vec4 out_color;

void main()
{
    out_color = vec4(1.0, 1.0, 1.0, 1.0);
}`;

GLuint compileShader(string src, GLenum type)
{
    GLuint shader = glCreateShader(type);
    auto strz = src.toStringz;
    glShaderSource(shader, 1, &strz, null);
    glCompileShader(shader);

    GLint status;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);

    if (status != GL_TRUE)
    {
        GLsizei len;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &len);
        if (len > 1)
        {
            GLchar[] buf = new GLchar[len];
            glGetShaderInfoLog(shader, len, null, &buf[0]);
            assert(false, buf);
        }
        assert(false, "unknown error");
    }
    return shader;
}

GLuint linkProgram(GLuint vs, GLuint fs)
{
    auto program = glCreateProgram();
    glAttachShader(program, vs);
    glAttachShader(program, fs);
    glLinkProgram(program);

    GLint status;
    glGetProgramiv(program, GL_LINK_STATUS, &status);

    if (status != GL_TRUE)
    {
        GLint len;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &len);
        if (len > 1)
        {
            GLchar[] buf = new GLchar[len];
            glGetProgramInfoLog(program, len, null, buf.ptr);
            assert(false, buf);
        }
        assert(false, "unknown error");
    }
    return program;
}

int main()
{
    if (glfwInit() == GL_FALSE)
    {
        std.stdio.stderr.writeln("Cannot initialize GLFW");
        return 1;
    }
    scope (exit) glfwTerminate();

    // OpenGL 3.3
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    auto window = glfwCreateWindow(640, 480, "Hello!", null, null);
    if (window is null)
    {
        std.stdio.stderr.writeln("Cannot create GLFW window.");
        return 1;
    }
    glfwMakeContextCurrent(window);

    GLSupport support = loadOpenGL();
    if (support == GLSupport.noLibrary || support == GLSupport.noContext)
    {
        std.stdio.stderr.writeln(support);
        return 1;
    }

    auto vs = compileShader(VS_SRC, GL_VERTEX_SHADER);
    auto fs = compileShader(FS_SRC, GL_FRAGMENT_SHADER);

    auto program = linkProgram(vs, fs);

    GLuint vao;
    GLuint vbo;

    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);

    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER ,vbo);
    glBufferData(GL_ARRAY_BUFFER,
                 (VERTEX_DATA.length * GLfloat.sizeof),
                 cast(void*) &VERTEX_DATA[0],
                 GL_STATIC_DRAW);

    glUseProgram(program);
    glBindFragDataLocation(program, 0, "out_color".toStringz());

    auto posAttr = glGetAttribLocation(program, "position".toStringz());
    glEnableVertexAttribArray(posAttr);
    glVertexAttribPointer(posAttr, 2, GL_FLOAT, GL_FALSE, 0, null);

    while (glfwWindowShouldClose(window) == GL_FALSE)
    {
        glClearColor(0.3, 0.3, 0.3, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        glDrawArrays(GL_TRIANGLES, 0, 3);

        glfwSwapBuffers(window);
        glfwWaitEvents();
    }

    return 0;
}
