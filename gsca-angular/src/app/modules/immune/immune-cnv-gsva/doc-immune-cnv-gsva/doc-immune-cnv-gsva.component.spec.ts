import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocImmuneCnvGsvaComponent } from './doc-immune-cnv-gsva.component';

describe('DocImmuneCnvGsvaComponent', () => {
  let component: DocImmuneCnvGsvaComponent;
  let fixture: ComponentFixture<DocImmuneCnvGsvaComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocImmuneCnvGsvaComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocImmuneCnvGsvaComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
