using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class RenderCubemapWizard : ScriptableWizard{

    public Transform renderFromPosition;
    public Cubemap cubemap;

    void OnWizardUpdate()
    {
        helpString = "Selcet transform to render from and cubemap to render into...";
        isValid = (renderFromPosition != null) && (cubemap != null);
    }

    void OnWizardCreate()
    {
        GameObject go = new GameObject("CubemapCamera");
        go.AddComponent<Camera>();
        go.transform.position = renderFromPosition.position;
        go.GetComponent<Camera>().RenderToCubemap(cubemap);

        DestroyImmediate(go);
    }

    [MenuItem("GameObject/渲染cubemap")]
    static void RenderCubemap()
    {
        ScriptableWizard.DisplayWizard<RenderCubemapWizard>("渲染cubemap", "渲染!!!");
    }



}
