using UnityEditor;
using UnityEngine;
using System.Collections.Generic;

public class PlugVertexColorsTool
{
    [MenuItem("Tools/模型平均法线写入顶点色数据")]
    public static void WirteAverageNormalToTangentToos()
    {
        MeshFilter[] meshFilters = Selection.activeGameObject.GetComponentsInChildren<MeshFilter>();
        foreach (var meshFilter in meshFilters)
        {
            Mesh mesh = meshFilter.sharedMesh;
            WirteAverageNormalToTangent(mesh);
        }

        // 复制这些代码，更改这个参数的名字可以使用
        SkinnedMeshRenderer[] skinMeshRenders = Selection.activeGameObject.GetComponentsInChildren<SkinnedMeshRenderer>();
        foreach (var skinMeshRender in skinMeshRenders)
        {
            Mesh mesh = skinMeshRender.sharedMesh;
            WirteAverageNormalToTangent(mesh);
        }
    }

    // 函数
    private static void WirteAverageNormalToTangent(Mesh mesh)
    {
        var averageNormalHash = new Dictionary<Vector3, Vector3>();
        for (var j = 0; j < mesh.vertexCount; j++)
        {
            if (!averageNormalHash.ContainsKey(mesh.vertices[j]))
            {
                averageNormalHash.Add(mesh.vertices[j], mesh.normals[j]);
            }
            else
            {
                averageNormalHash[mesh.vertices[j]] =
                    (averageNormalHash[mesh.vertices[j]] + mesh.normals[j]).normalized;
            }
        }

        var averageNormals = new Vector3[mesh.vertexCount];
        for (var j = 0; j < mesh.vertexCount; j++)
        {
            averageNormals[j] = averageNormalHash[mesh.vertices[j]];
        }

        // 创建顶点颜色数组
        Color[] vertexColors = new Color[mesh.vertexCount];
        for (var j = 0; j < mesh.vertexCount; j++)
        {
            // 将法线从 [-1, 1] 转换为 [0, 1] 范围，并存储到顶点颜色的 RGB 分量
            vertexColors[j] = new Color(
                averageNormals[j].x * 0.5f + 0.5f,
                averageNormals[j].y * 0.5f + 0.5f,
                averageNormals[j].z * 0.5f + 0.5f,
                1.0f // Alpha 分量可以设置为 1.0
            );
        }
        mesh.colors = vertexColors; // 将顶点颜色应用到 Mesh

        Debug.Log("平均法线已成功写入顶点颜色。");
    }
}