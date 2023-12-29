using System.Collections;
using UnityEngine;
using UnityEngine.UI;

public class SimplePlayer : MonoBehaviour
{
    [SerializeField] private Image _image;
    [SerializeField] private Sprite _a;
    [SerializeField] private Sprite _b;
    
    [SerializeField] private Material _material;

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Q))
            Play();
    }

    private void Play()
    {
        StartCoroutine(Playing());
    }

    private IEnumerator Playing()
    {
        var t = 0f;
        _material.SetFloat("_IsDissolve", 0.0f);
        _image.sprite = _a;
        while (t < 1)
        {
            t += Time.deltaTime;
            _material.SetFloat("_Progress", t);
            yield return null;
        }

        yield return new WaitForSeconds(3);
        _material.SetFloat("_IsDissolve", 1.0f);
        t = 0f;
        while (t < 1 / 2f)
        {
            t += Time.deltaTime;
            _material.SetFloat("_Progress", (1/2f - t) * 2);
            yield return null;
        }
        
        t = 0f;
        _material.SetFloat("_IsDissolve", 0.0f);

        _image.sprite = _b;
        while (t < 1)
        {
            t += Time.deltaTime;
            _material.SetFloat("_Progress", t);
            yield return null;
        }
        
        yield return new WaitForSeconds(2);
        _material.SetFloat("_IsDissolve", 1.0f);

        t = 0f;
        while (t < 1 / 2f)
        {
            t += Time.deltaTime;
            _material.SetFloat("_Progress", (1/2f - t) * 2);
            yield return null;
        }
    }
}
