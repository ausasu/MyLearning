using UnityEngine;

public class NormalsReplacementShader : MonoBehaviour
{
    [SerializeField]
    Shader normalsShader;

    private RenderTexture renderTexture;
    private new Camera camera;

    private void Start()
    {
        Camera thisCamera = GetComponent<Camera>();   // 获取摄像机像素宽度和高度

        // Create a render texture matching the main camera's current dimensions.
        renderTexture = new RenderTexture(thisCamera.pixelWidth, thisCamera.pixelHeight, 24);  // 创建纹理对象，存储颜色信息，格式为24
        // Surface the render texture as a global variable, available to all shaders.
        Shader.SetGlobalTexture("_CameraNormalsTexture", renderTexture);  // 为这个纹理命名为_CameraNormalsTexture

        // Setup a copy of the camera to render the scene using the normals shader.
        GameObject copy = new GameObject("Normals camera");   // 创建一个物体为其添加一个摄像机
        camera = copy.AddComponent<Camera>();
        camera.CopyFrom(thisCamera);   // 复制到thisCamera这个摄像机中
        camera.transform.SetParent(transform);  // 将新的摄像机的目标纹理设置为renderTexture
        camera.targetTexture = renderTexture;
        camera.SetReplacementShader(normalsShader, "RenderType");
        camera.depth = thisCamera.depth - 1;  // 深度-1，保证它在渲染顺序上位于当前摄像机之前
    }
}
