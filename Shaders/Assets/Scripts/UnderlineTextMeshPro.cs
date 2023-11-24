using System.Collections;
using System.Collections.Generic;
using System.Linq;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class UnderlineTextMeshPro : MonoBehaviour
{
    [SerializeField] private TextMeshProUGUI _text;
    [SerializeField] private string _underlineLinkTag;
    [SerializeField] private Image _templateUnderline;

    public float HeightOffset = 1;
    public float Velocity = 1;

    private readonly List<GameObject> _underlines = new();
    private Coroutine _coroutine;

    public void Play()
    {
        Stop();
        _coroutine = StartCoroutine(UnderlinePlaying(Velocity));
    }

    public void Stop()
    {
        foreach (var underline in _underlines) 
            Destroy(underline);
        
        _underlines.Clear();

        if (_coroutine != null)
            StopCoroutine(_coroutine);
        _coroutine = null;
    }
    
    private IEnumerator UnderlinePlaying(float velocity)
    {
        var points = CornerPoints(_text.textInfo, _text.textInfo.linkInfo, _underlineLinkTag).ToArray();
        for (var i = 0; i < points.Length; i += 2) 
            yield return Underlining(points[i], points[i + 1], velocity);
    }

    private IEnumerator Underlining(Vector2 start, Vector2 end, float velocity)
    {
        var underline = Instantiate(_templateUnderline, _text.transform);
        _underlines.Add(underline.gameObject);
        underline.rectTransform.localPosition = start;
        var initialPoint = underline.rectTransform.localPosition - new Vector3(0, HeightOffset, 0);
        var line = end.x - start.x;
        var t = 0f;

        while (t < velocity * line / 100)
        {
            var width = Mathf.Lerp(0, line, t / (velocity * line / 100));
            underline.rectTransform.sizeDelta = new Vector2(width, underline.rectTransform.sizeDelta.y);
            underline.rectTransform.localPosition = initialPoint + Vector3.right * width / 2;
            t += Time.deltaTime;
            yield return null;
        }
    }
    
    private static IEnumerable<Vector3> CornerPoints(TMP_TextInfo text, IEnumerable<TMP_LinkInfo> links, string linkTag)
    {
        var firstCharacterOnLineIndexes = text.lineInfo.Select(c => c.firstCharacterIndex).ToArray();
        
        foreach (var link in links.Where(link => link.GetLinkID() == linkTag))
        {
            var startIndex = link.linkTextfirstCharacterIndex;
            var endIndex = link.linkTextfirstCharacterIndex + link.linkTextLength;
            var firstCharacter = text.characterInfo[startIndex];
            var previousBottomRight = firstCharacter.bottomRight;
            yield return firstCharacter.bottomLeft;

            for (var i = startIndex + 1; i < endIndex - 1; i++)
            {
                var character = text.characterInfo[i];
                var bottomLeft = character.bottomLeft;
                var bottomRight = character.bottomRight;

                if (firstCharacterOnLineIndexes.Contains(i))
                {
                    yield return previousBottomRight;
                    yield return bottomLeft;
                }

                previousBottomRight = bottomRight;
            }

            yield return text.characterInfo[endIndex - 1].bottomRight;
        }
    }
}