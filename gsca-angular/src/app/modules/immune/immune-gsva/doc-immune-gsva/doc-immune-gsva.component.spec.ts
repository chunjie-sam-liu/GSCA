import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocImmuneGsvaComponent } from './doc-immune-gsva.component';

describe('DocImmuneGsvaComponent', () => {
  let component: DocImmuneGsvaComponent;
  let fixture: ComponentFixture<DocImmuneGsvaComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocImmuneGsvaComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocImmuneGsvaComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
